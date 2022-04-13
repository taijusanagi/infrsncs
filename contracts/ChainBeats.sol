//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

import "./ByteSwapping.sol";
import "./Omnichain.sol";
import "./WAVE.sol";
import "./SVG.sol";

contract ChainBeats is ERC721, Ownable, Omnichain {
    uint256 public supplied;
    uint256 public startTokenId;
    uint256 public endTokenId;
    uint256 public mintPrice;

    mapping(uint256 => bytes32) public birthChainSeeds;
    mapping(uint256 => bytes32) public tokenIdSeeds;

    constructor(
        address layerZeroEndpoint,
        uint256 startTokenId_,
        uint256 endTokenId_,
        uint256 mintPrice_
    ) ERC721("ChainBeats", "CB") Omnichain(layerZeroEndpoint) {
        startTokenId = startTokenId_;
        endTokenId = endTokenId_;
        mintPrice = mintPrice_;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    //burnの時にseed消す

    function mint(address to) public payable virtual {
        require(msg.value >= mintPrice, "ChainBeats: msg value invalid");
        uint256 tokenId = startTokenId + supplied;
        require(tokenId <= endTokenId, "ChainBeats: mint finished");
        tokenIdSeeds[tokenId] = keccak256(
            abi.encodePacked(blockhash(block.number - 1), tokenId)
        );
        _safeMint(to, tokenId);
        supplied++;
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

    function _registerTraverse(
        uint256 tokenId,
        bytes32 birthChainSeed,
        bytes32 tokenIdSeed
    ) internal override {
        birthChainSeeds[tokenId] = birthChainSeed;
        tokenIdSeeds[tokenId] = tokenIdSeed;
    }

    function _burn(uint256 tokenId) internal override {
        if (birthChainSeeds[tokenId] != "") {
            delete birthChainSeeds[tokenId];
        }
        delete tokenIdSeeds[tokenId];
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
            '{"name": "ChainBeats #', // solhint-disable-line quotes
            Strings.toString(tokenId),
            '", "description": "A unique beat represented entirely on-chain.', // solhint-disable-line quotes
            '", "image": "', // solhint-disable-line quotes
            svg,
            '", "animation_url": "', // solhint-disable-line quotes
            wave,
            '", "attributes": [', // solhint-disable-line quotes
            '{"trait_type": "SAMPLE RATE","value": ', // solhint-disable-line quotes
            Strings.toString(sampleRate),
            "},",
            '{"trait_type": "HERTS","value": ', // solhint-disable-line quotes
            Strings.toString(hertz),
            "},",
            '{"trait_type": "DUTY CYCLE","value": ', // solhint-disable-line quotes
            Strings.toString(dutyCycle),
            "}]}"
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
        override
        returns (bytes32 birthChainSeed)
    {
        if (_isOnBirthChain(tokenId)) {
            birthChainSeed = blockhash(0);
        } else {
            birthChainSeed = birthChainSeeds[tokenId];
        }
    }

    function _getTokenIdSeed(uint256 tokenId)
        internal
        view
        override
        returns (bytes32 tokenIdSeed)
    {
        tokenIdSeed = tokenIdSeeds[tokenId];
    }
}
