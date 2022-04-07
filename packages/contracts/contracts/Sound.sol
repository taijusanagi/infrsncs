//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

import "hardhat/console.sol";

contract Sound is ERC721 {
    mapping(uint256 => bytes32) seeds;

    function random(uint256 tokenId) internal view returns (uint256) {
        uint256 randomnumber = uint256(
            keccak256(abi.encodePacked(seeds[tokenId], tokenId))
        ) % 990;
        return randomnumber + 10;
    }

    function reverseUint32(uint32 input) internal pure returns (uint32 v) {
        v = input;
        v = ((v & 0xFF00FF00) >> 8) | ((v & 0x00FF00FF) << 8);
        v = (v >> 16) | (v << 16);
    }

    function reverseUint16(uint16 input) internal pure returns (uint16 v) {
        v = input;
        v = (v >> 8) | (v << 8);
    }

    // function reverseUint8(uint8 input) internal pure returns (uint8 v) {
    //     v = input;
    //     v = (v >> 4) | (v << 4);
    // }

    using Counters for Counters.Counter;
    using Strings for uint256;
    using Base64 for bytes;

    Counters.Counter private _tokenIdTracker;

    string public imageUrlBase;
    string public animationUrlBase;

    bytes4 constant chunkID = "RIFF";
    // dev: this setting makes difference from original js implementation, so need further investigation
    uint32 constant chunkSize = 4 + (8 + subchunk1Size) + (8 + subchunk2Size);
    bytes4 constant format = "WAVE";

    bytes4 constant subchunk1ID = "fmt ";
    uint32 constant subchunk1Size = 16;
    uint16 constant audioFormat = 1;
    uint16 constant numChannels = 1;
    uint32 constant sampleRate = 3000;
    uint32 constant byteRate = (sampleRate * numChannels * bitsPerSample) / 8;
    uint16 constant blockAlign = (numChannels * bitsPerSample) / 8;
    uint16 constant bitsPerSample = 16;

    bytes4 constant subchunk2ID = "data";
    uint32 constant subchunk2Size =
        (sampleRate * numChannels * bitsPerSample) / 8;

    int16 constant crest = 16383;
    int16 constant trough = -16383;

    constructor() ERC721("Sound", "SOUND") {}

    function riffChunk() public pure returns (bytes memory) {
        return abi.encodePacked(chunkID, chunkSize, format);
    }

    function fmtChunk() public pure returns (bytes memory) {
        return
            abi.encodePacked(
                subchunk1ID,
                reverseUint32(subchunk1Size),
                reverseUint16(audioFormat),
                reverseUint16(numChannels),
                reverseUint32(sampleRate),
                reverseUint32(byteRate),
                reverseUint16(blockAlign),
                reverseUint16(bitsPerSample)
            );
    }

    function dataChunkPrefix() public pure returns (bytes memory) {
        return abi.encodePacked(subchunk2ID, reverseUint32(subchunk2Size));
    }

    function getWavePrefix() public pure returns (bytes memory) {
        return abi.encodePacked(riffChunk(), fmtChunk(), dataChunkPrefix());
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "Sound: URI query for nonexistent token");
        bytes memory metadata = getMetadata(tokenId);
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    metadata.encode()
                )
            );
    }

    function mint(address to) external payable virtual {
        uint256 tokenId = _tokenIdTracker.current();
        seeds[tokenId] = blockhash(block.number - 1);
        _mint(to, tokenId);
        _tokenIdTracker.increment();
    }

    function getMetadata(uint256 tokenId) public view returns (bytes memory) {
        bytes memory data;
        bool isUp = false;

        bytes memory up;
        bytes memory down;

        bytes memory crestBytes = abi.encodePacked(
            reverseUint16(uint16(crest))
        );
        bytes memory troughBytes = abi.encodePacked(
            reverseUint16(uint16(trough))
        );

        uint256 ramdom = random(tokenId);

        for (uint256 i = 0; i < ramdom; i++) {
            up = abi.encodePacked(up, crestBytes);
            down = abi.encodePacked(down, troughBytes);
        }

        for (uint256 i = 0; i < sampleRate / ramdom; i++) {
            data = abi.encodePacked(data, isUp ? up : down);
            isUp = !isUp;
        }

        bytes memory sound = abi.encodePacked(
            "data:audio/wav;base64,",
            abi.encodePacked(getWavePrefix(), data).encode()
        );

        return
            abi.encodePacked(
                '{"name": "Sound #',
                tokenId.toString(),
                '", "description": "A unique piece of sound represented entirely on-chain.',
                '", "animation_url": "',
                sound,
                '"}'
            );
    }
}
