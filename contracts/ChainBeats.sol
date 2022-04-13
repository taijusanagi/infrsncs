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

    mapping(uint256 => bytes32) public seeds;

    constructor(
        address _layerZeroEndpoint,
        uint256 _startTokenId,
        uint256 _endTokenId,
        uint256 _mintPrice
    ) ERC721("ChainBeats", "CB") Omnichain(_layerZeroEndpoint) {
        startTokenId = _startTokenId;
        endTokenId = _endTokenId;
        mintPrice = _mintPrice;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function mint(address to) public payable virtual {
        require(msg.value >= mintPrice, "ChainBeats: msg value invalid");
        uint256 tokenId = startTokenId + supplied;
        require(tokenId <= endTokenId, "ChainBeats: mint finished");
        seeds[tokenId] = keccak256(
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
        returns (string memory tokenURI)
    {
        require(_exists(tokenId), "ChainBeats: nonexistent token");
        bytes memory metadata = _getMetadata(tokenId);
        tokenURI = string(
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
            uint256 sampleRate,
            uint256 hertz,
            uint256 dutyCycle,
            string memory wave,
            string memory svg
        )
    {
        uint256 genesisSeed = _genesisSeed();
        uint256 tokenIdSeed = _tokenIdSeed(tokenId);
        sampleRate = WAVE.calculateSampleRate(genesisSeed);
        hertz = WAVE.calculateHertz(tokenIdSeed);
        dutyCycle = WAVE.calculateDutyCycle(tokenIdSeed);
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

    function _getMetadata(uint256 tokenId)
        internal
        view
        returns (bytes memory metadata)
    {
        (
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

    function _genesisSeed() internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(blockhash(0))));
    }

    function _tokenIdSeed(uint256 tokenId) internal view returns (uint256) {
        return uint256(seeds[tokenId]);
    }
}
