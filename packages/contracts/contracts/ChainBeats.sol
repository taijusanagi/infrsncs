//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

import "solidity-examples/contracts/NonBlockingReceiver.sol";
import "solidity-examples/contracts/interfaces/ILayerZeroEndpoint.sol";

import "./ByteSwapping.sol";
import "./Audio.sol";
import "./Image.sol";

contract ChainBeats is ERC721, Ownable, NonblockingReceiver {
    using Strings for uint256;
    using Base64 for bytes;

    uint256 public supplied;
    uint256 public startTokenId;
    uint256 public endTokenId;
    uint256 public mintPrice;

    // mapping(uint256 => bytes32) public genesisBlockHashes;
    mapping(uint256 => uint256) public blockNumbers;

    constructor(
        address _layerZeroEndpoint,
        uint256 _startTokenId,
        uint256 _endTokenId,
        uint256 _mintPrice
    ) ERC721("ChainBeats", "CB") {
        endpoint = ILayerZeroEndpoint(_layerZeroEndpoint);
        startTokenId = _startTokenId;
        endTokenId = _endTokenId;
        mintPrice = _mintPrice;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function mint(address to) public payable virtual {
        require(msg.value >= mintPrice, "ChainBeats: msg value is invalid");
        uint256 tokenId = startTokenId + supplied;
        require(tokenId <= endTokenId, "ChainBeats: mint already finished");
        blockNumbers[tokenId] = block.number;
        _safeMint(to, tokenId);
        supplied++;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ChainBeats: URI query for nonexistent token"
        );
        bytes memory metadata = getMetadata(tokenId);
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    metadata.encode()
                )
            );
    }

    function getMetadata(uint256 tokenId) public view returns (bytes memory) {
        bytes32 sampleRateSeed = getSampleRateSeed();
        bytes32 waveAndDutyCycleSeed = getWaveAndDutyCycleSeed(tokenId);
        uint256 sampleRate = Audio.calculateSampleRate(sampleRateSeed);
        uint256 waveWidth = Audio.calculateWaveWidth(
            sampleRate,
            waveAndDutyCycleSeed
        );
        uint256 dutyCycle = Audio.calculateDutyCycle(waveAndDutyCycleSeed);
        bytes memory audio = Audio.getAudio(sampleRate, waveWidth, dutyCycle);
        bytes memory encodedAudio = Audio.encode(uint32(sampleRate), audio);
        bytes memory audioDataURI = abi.encodePacked(
            "data:audio/wav;base64,",
            encodedAudio.encode()
        );
        bytes memory svg = Image.generateSVG(encodedAudio);
        return
            abi.encodePacked(
                '{"name": "ChainBeats #',
                tokenId.toString(),
                '", "description": "A unique beat represented entirely on-chain.',
                '", "image": "',
                svg,
                '", "animation_url": "',
                audioDataURI,
                '", "attributes": [',
                '{"trait_type": "SAMPLE RATE","value": "',
                sampleRate.toString(),
                '"},',
                '{"trait_type": "WAVE WIDTH","value": "',
                waveWidth.toString(),
                '"},',
                '{"trait_type": "DUTY CYCLE","value": "',
                dutyCycle.toString(),
                '%"}]}'
            );
    }

    function getSampleRateSeed() internal view returns (bytes32) {
        return keccak256(abi.encodePacked(blockhash(0)));
    }

    function getWaveAndDutyCycleSeed(uint256 tokenId)
        internal
        view
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    blockhash(0),
                    blockhash(blockNumbers[tokenId]),
                    tokenId
                )
            );
    }

    function transferOmnichainNFT(uint16 _chainId, uint256 omniChainNFT_tokenId)
        public
        payable
    {
        require(
            msg.sender == ownerOf(omniChainNFT_tokenId),
            "Message sender must own the OmnichainNFT."
        );
        require(
            trustedSourceLookup[_chainId].length != 0,
            "This chain is not a trusted source source."
        );

        _burn(omniChainNFT_tokenId);

        bytes memory payload = abi.encode(msg.sender, omniChainNFT_tokenId);
        uint16 version = 1;
        uint256 gas = 225000;
        bytes memory adapterParams = abi.encodePacked(version, gas);
        (uint256 quotedLayerZeroFee, ) = endpoint.estimateFees(
            _chainId,
            address(this),
            payload,
            false,
            adapterParams
        );
        require(
            msg.value >= quotedLayerZeroFee,
            "Not enough gas to cover cross chain transfer."
        );

        endpoint.send{value: msg.value}(
            _chainId,
            trustedSourceLookup[_chainId],
            payload,
            payable(msg.sender),
            address(0x0),
            adapterParams
        );
    }

    function _LzReceive(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint64 _nonce,
        bytes memory _payload
    ) internal override {
        (address _dstOmnichainNFTAddress, uint256 omnichainNFT_tokenId) = abi
            .decode(_payload, (address, uint256));
        _safeMint(_dstOmnichainNFTAddress, omnichainNFT_tokenId);
    }
}
