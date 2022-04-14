//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

import "solidity-examples/contracts/NonBlockingReceiver.sol";
import "solidity-examples/contracts/interfaces/ILayerZeroEndpoint.sol";
import "solidity-examples/contracts/interfaces/ILayerZeroUserApplicationConfig.sol";

import "./ByteSwapping.sol";
import "./WAVE.sol";
import "./SVG.sol";

contract ChainBeats is
    ERC721,
    Ownable,
    NonblockingReceiver,
    ILayerZeroUserApplicationConfig
{
    uint256 public supplied;
    uint256 public startTokenId;
    uint256 public endTokenId;
    uint256 public mintPrice;

    uint256 public gasForDestinationLzReceive = 350000;

    mapping(uint256 => uint256) public mintedBlockNumbers;
    mapping(uint256 => bytes32) public birthChainGenesisBlockHashes;

    constructor(
        address layerZeroEndpoint,
        uint256 startTokenId_,
        uint256 endTokenId_,
        uint256 mintPrice_
    ) ERC721("ChainBeats", "CB") {
        endpoint = ILayerZeroEndpoint(layerZeroEndpoint);
        startTokenId = startTokenId_;
        endTokenId = endTokenId_;
        mintPrice = mintPrice_;
    }

    function setConfig(
        uint16 version,
        uint16 chainId,
        uint256 configType,
        bytes calldata config
    ) external override onlyOwner {
        endpoint.setConfig(version, chainId, configType, config);
    }

    function setSendVersion(uint16 version) external override onlyOwner {
        endpoint.setSendVersion(version);
    }

    function setReceiveVersion(uint16 version) external override onlyOwner {
        endpoint.setReceiveVersion(version);
    }

    function forceResumeReceive(uint16 srcChainId, bytes calldata srcAddress)
        external
        override
        onlyOwner
    {
        endpoint.forceResumeReceive(srcChainId, srcAddress);
    }

    function setGasForDestinationLzReceive(uint256 gasForDestinationLzReceive_)
        external
        onlyOwner
    {
        gasForDestinationLzReceive = gasForDestinationLzReceive_;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function mint(address to) public payable virtual {
        require(msg.value >= mintPrice, "ChainBeats: msg value invalid");
        uint256 tokenId = startTokenId + supplied;
        require(tokenId <= endTokenId, "ChainBeats: mint finished");
        _safeMint(to, tokenId);
        _registerTraversableAttributes(tokenId, block.number, blockhash(0));
        supplied++;
    }

    function transferOmnichainNFT(uint16 chainId, uint256 tokenId)
        public
        payable
    {
        require(
            msg.sender == ownerOf(tokenId),
            "ChainBeats: Message sender must own the OmnichainNFT."
        );
        require(
            trustedSourceLookup[chainId].length != 0,
            "ChainBeats: This chain is not a trusted source source."
        );

        (
            uint256 mintedBlockNumber,
            bytes32 birthChainGenesisBlockHash
        ) = getTraversableAttributes(tokenId);

        bytes memory payload = abi.encode(
            msg.sender,
            tokenId,
            mintedBlockNumber,
            birthChainGenesisBlockHash
        );
        uint16 version = 1;
        bytes memory adapterParams = abi.encodePacked(
            version,
            gasForDestinationLzReceive
        );
        (uint256 quotedLayerZeroFee, ) = endpoint.estimateFees(
            chainId,
            address(this),
            payload,
            false,
            adapterParams
        );
        require(
            msg.value >= quotedLayerZeroFee,
            "ChainBeats: Not enough gas to cover cross chain transfer."
        );

        delete mintedBlockNumbers[tokenId];
        delete birthChainGenesisBlockHashes[tokenId];
        _burn(tokenId);

        // solhint-disable-next-line check-send-result
        endpoint.send{value: msg.value}(
            chainId,
            trustedSourceLookup[chainId],
            payload,
            payable(msg.sender),
            address(0x0),
            adapterParams
        );
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory tokenURI_)
    {
        require(_exists(tokenId), "ChainBeats: nonexistent token");
        bytes memory metadata = _getMetadata(tokenId);
        tokenURI_ = string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(metadata)
            )
        );
    }

    function getData(uint256 tokenId)
        public
        view
        returns (
            bytes32 birthChainSeed,
            bytes32 tokenIdSeed,
            uint256 sampleRate,
            uint256 hertz,
            uint256 dutyCycle,
            string memory wave,
            string memory svg
        )
    {
        birthChainSeed = _getBirthChainSeed(tokenId);
        tokenIdSeed = _getTokenIdSeed(tokenId);
        sampleRate = WAVE.calculateSampleRate(uint256(birthChainSeed));
        hertz = WAVE.calculateHertz(uint256(tokenIdSeed));
        dutyCycle = WAVE.calculateDutyCycle(uint256(tokenIdSeed));
        wave = string(WAVE.generate(sampleRate, hertz, dutyCycle));
        svg = string(SVG.generate(wave));
    }

    function getMetadata(uint256 tokenId)
        public
        view
        returns (string memory metadata)
    {
        metadata = string(_getMetadata(tokenId));
    }

    function getTraversableAttributes(uint256 tokenId)
        public
        view
        returns (uint256 mintedBlockNumber, bytes32 birthChainGenesisBlockHash)
    {
        mintedBlockNumber = mintedBlockNumbers[tokenId];
        birthChainGenesisBlockHash = birthChainGenesisBlockHashes[tokenId];
    }

    function _registerTraversableAttributes(
        uint256 tokenId,
        uint256 mintedBlockNumber,
        bytes32 birthChainGenesisBlockHash
    ) internal {
        mintedBlockNumbers[tokenId] = mintedBlockNumber;
        birthChainGenesisBlockHashes[tokenId] = birthChainGenesisBlockHash;
    }

    // solhint-disable-next-line func-name-mixedcase
    function _LzReceive(
        uint16 _srcChainId, // solhint-disable-line no-unused-vars
        bytes memory _srcAddress, // solhint-disable-line no-unused-vars
        uint64 _nonce, // solhint-disable-line no-unused-vars
        bytes memory payload
    ) internal override {
        (
            address dstOmnichainNFTAddress,
            uint256 omnichainNFTTokenId,
            uint256 mintedBlockNumber,
            bytes32 birthChainGenesisBlockHash
        ) = abi.decode(payload, (address, uint256, uint256, bytes32));
        _safeMint(dstOmnichainNFTAddress, omnichainNFTTokenId);
        _registerTraversableAttributes(
            omnichainNFTTokenId,
            mintedBlockNumber,
            birthChainGenesisBlockHash
        );
    }

    function _getMetadata(uint256 tokenId)
        internal
        view
        returns (bytes memory metadata)
    {
        (
            bytes32 birthChainSeed,
            bytes32 tokenIdSeed,
            uint256 sampleRate,
            uint256 hertz,
            uint256 dutyCycle,
            string memory wave,
            string memory svg
        ) = getData(tokenId);

        metadata = abi.encodePacked(
            "{",
            '"name":"ChainBeats #', // solhint-disable-line quotes
            Strings.toString(tokenId),
            '","description": "A unique beat represented entirely on-chain."',
            ',"image":"', // solhint-disable-line quotes
            svg,
            '","animation_url":"', // solhint-disable-line quotes
            wave,
            '","attributes":',
            abi.encodePacked(
                "[{",
                '"trait_type":"SAMPLE RATE","value":', // solhint-disable-line quotes
                Strings.toString(sampleRate),
                "},{",
                '"trait_type":"HERTS","value":', // solhint-disable-line quotes
                Strings.toString(hertz),
                "},{",
                '"trait_type":"DUTY CYCLE","value":', // solhint-disable-line quotes
                Strings.toString(dutyCycle),
                "},{",
                '"trait_type":"BIRTH CHAIN SEED","value":"', // solhint-disable-line quotes
                Strings.toHexString(uint256(birthChainSeed), 32),
                '"},{', // solhint-disable-line quotes
                '"trait_type":"TOKEN ID SEED","value":"', // solhint-disable-line
                Strings.toHexString(uint256(tokenIdSeed), 32),
                '"}]' // solhint-disable-line
            ),
            "}"
        );
    }

    function _isOnBirthChain(uint256 tokenId)
        internal
        view
        returns (bool isOnBirthChain)
    {
        isOnBirthChain = (startTokenId <= tokenId || tokenId <= endTokenId);
    }

    function _getBirthChainSeed(uint256 tokenId)
        internal
        view
        returns (bytes32 birthChainSeed)
    {
        birthChainSeed = birthChainGenesisBlockHashes[tokenId];
    }

    function _getTokenIdSeed(uint256 tokenId)
        internal
        view
        returns (bytes32 tokenIdSeed)
    {
        tokenIdSeed = keccak256(
            abi.encodePacked(mintedBlockNumbers[tokenId], tokenId)
        );
    }
}
