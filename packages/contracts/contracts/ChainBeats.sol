//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

import "./ByteSwapping.sol";
import "./Audio.sol";
import "./Image.sol";

contract ChainBeats is ERC721, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;
    using Base64 for bytes;

    Counters.Counter private _tokenIdTracker;

    mapping(uint256 => uint256) public blockNumbers;

    uint256 public constant supplyLimit = 1000;
    uint256 public constant mintPrice = 0.02 ether;

    constructor() ERC721("ChainBeats", "CB") {}

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function mint(address to) public payable virtual {
        require(msg.value == mintPrice, "ChainBeats: msg value is invalid");
        uint256 tokenId = _tokenIdTracker.current();
        require(tokenId < supplyLimit, "ChainBeats: mint is already finished");
        blockNumbers[tokenId] = block.number;
        _mint(to, tokenId);
        _tokenIdTracker.increment();
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
        bytes32 waveSeed = getWaveSeed(tokenId);
        bytes32 pulseSeed = getPulseSeed();
        uint256 waveWidth = Audio.calculateWaveWidth(waveSeed);
        uint256 pulseWidth = Audio.calculatePulseWidth(pulseSeed);
        bytes memory audio = Audio.getAudio(waveWidth, pulseWidth);
        bytes memory audioDataURI = abi.encodePacked(
            "data:audio/wav;base64,",
            Audio.encode(audio).encode()
        );
        bytes memory svg = Image.generateSVG(audio);
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
                '{"trait_type": "WAVE WIDTH","value": "',
                waveWidth.toString(),
                '"},',
                '{"trait_type": "PULSE WIDTH","value": "',
                pulseWidth.toString(),
                '"}]}'
            );
    }

    function getPulseSeed() internal view returns (bytes32) {
        return keccak256(abi.encodePacked(blockhash(0)));
    }

    function getWaveSeed(uint256 tokenId) internal view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(blockhash(blockNumbers[tokenId]), tokenId)
            );
    }
}
