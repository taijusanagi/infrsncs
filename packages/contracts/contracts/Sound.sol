//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ByteSwapping.sol";

library Sound {
    bytes4 constant chunkID = "RIFF";
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

    int16 public constant crest = 16383;
    int16 public constant trough = -16383;

    uint256 public constant maxWaveWidth = 1200;
    uint256 public constant minimumWaveWidth = 30;
    uint256 public constant maxPulseWidth = 9900;
    uint256 public constant minimumPulseWidth = 100;
    uint256 public constant bsp = 10000;

    function riffChunk() internal pure returns (bytes memory) {
        return
            abi.encodePacked(
                chunkID,
                ByteSwapping.swapUint32(chunkSize),
                format
            );
    }

    function fmtSubChunk() internal pure returns (bytes memory) {
        return
            abi.encodePacked(
                subchunk1ID,
                ByteSwapping.swapUint32(subchunk1Size),
                ByteSwapping.swapUint16(audioFormat),
                ByteSwapping.swapUint16(numChannels),
                ByteSwapping.swapUint32(sampleRate),
                ByteSwapping.swapUint32(byteRate),
                ByteSwapping.swapUint16(blockAlign),
                ByteSwapping.swapUint16(bitsPerSample)
            );
    }

    function dataSubChunk(bytes memory data)
        internal
        pure
        returns (bytes memory)
    {
        return
            abi.encodePacked(
                subchunk2ID,
                ByteSwapping.swapUint32(subchunk2Size),
                data
            );
    }

    function encode(bytes memory data) internal pure returns (bytes memory) {
        return abi.encodePacked(riffChunk(), fmtSubChunk(), dataSubChunk(data));
    }

    function getSound(bytes32 seed) internal pure returns (bytes memory) {
        bytes memory data;

        bytes memory positive;
        bytes memory negative;

        bytes memory crestBytes = abi.encodePacked(
            ByteSwapping.swapUint16(uint16(crest))
        );

        bytes memory troughBytes = abi.encodePacked(
            ByteSwapping.swapUint16(uint16(trough))
        );

        uint256 waveWidthForToken = calculateWaveWidth(seed);
        uint256 pulseWidthForToken = calculatePulseWidth(seed);

        for (
            uint256 i = 0;
            i < (waveWidthForToken * pulseWidthForToken) / bsp;
            i++
        ) {
            positive = abi.encodePacked(positive, crestBytes);
        }
        for (
            uint256 i = 0;
            i < (waveWidthForToken * (bsp - pulseWidthForToken)) / bsp;
            i++
        ) {
            negative = abi.encodePacked(negative, troughBytes);
        }
        for (uint256 i = 0; i < sampleRate / waveWidthForToken; i++) {
            data = abi.encodePacked(data, i % 2 == 0 ? positive : negative);
        }
        return data;
    }

    function calculateWaveWidth(bytes32 seed) internal pure returns (uint256) {
        return
            (uint256(seed) % (maxWaveWidth - minimumWaveWidth)) +
            minimumWaveWidth;
    }

    function calculatePulseWidth(bytes32 seed) internal pure returns (uint256) {
        return
            (uint256(seed) % (maxPulseWidth - minimumPulseWidth)) +
            minimumWaveWidth;
    }
}
