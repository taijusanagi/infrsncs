//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ByteSwapping.sol";

import "hardhat/console.sol";

library Audio {
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
    int16 public constant upperAmplitude = 16383;
    int16 public constant lowerAmplitude = -16383;

    uint256 public constant maxWaveWidth = 8000;
    uint256 public constant minWaveWidth = 400;

    uint256 public constant maxDutyCycle = 99;
    uint256 public constant minDutyCycle = 1;
    uint256 public constant dutyCycleBase = 100;

    function calculateWaveWidth(bytes32 seed) internal view returns (uint256) {
        uint256 param = (uint256(seed) % (maxWaveWidth - minWaveWidth)) +
            minWaveWidth;

        // console.log(sampleRate % param);

        return (uint256(seed) % (maxWaveWidth - minWaveWidth)) + minWaveWidth;
    }

    function calculateDutyCycle(bytes32 seed) internal pure returns (uint256) {
        return (uint256(seed) % (maxDutyCycle - minDutyCycle)) + minWaveWidth;
    }

    function getAudio(uint256 waveWidth, uint256 dutyCycle)
        internal
        view
        returns (bytes memory)
    {
        bytes memory data;

        uint256 amplitudesLength = 1;
        while (waveWidth >= 2**amplitudesLength) {
            amplitudesLength++;
        }

        bytes[] memory upperAmplitudes = new bytes[](amplitudesLength);
        bytes[] memory lowerAmplitudes = new bytes[](amplitudesLength);

        upperAmplitudes[0] = abi.encodePacked(
            ByteSwapping.swapUint16(uint16(upperAmplitude))
        );
        lowerAmplitudes[0] = abi.encodePacked(
            ByteSwapping.swapUint16(uint16(lowerAmplitude))
        );

        for (uint256 i = 0; i < amplitudesLength - 1; i++) {
            upperAmplitudes[i + 1] = abi.encodePacked(
                upperAmplitudes[i],
                upperAmplitudes[i]
            );
            lowerAmplitudes[i + 1] = abi.encodePacked(
                lowerAmplitudes[i],
                lowerAmplitudes[i]
            );
        }

        uint256 upperWaveWidth = (waveWidth * dutyCycle) / dutyCycleBase;
        uint256 lowerWaveWidth = (waveWidth * (dutyCycleBase - dutyCycle)) /
            dutyCycleBase;

        uint256 adjustWaveWidth = sampleRate % waveWidth;

        // ここで辺の合計がwaveLengthになるように調整入るかもしれない
        bytes memory upperWave;
        bytes memory lowerWave;
        bytes memory adjustWave;

        uint256 upperAmplitudesIndex = amplitudesLength - 1;
        while (upperWave.length < upperWaveWidth * 2) {
            uint256 gap = upperWaveWidth * 2 - upperWave.length;
            console.log(gap);
            for (uint256 i = upperAmplitudesIndex; i >= 0; i--) {
                if (gap >= upperAmplitudes[i].length) {
                    upperWave = abi.encodePacked(upperWave, upperAmplitudes[i]);

                    upperAmplitudesIndex = i;
                    break;
                }
            }
        }

        uint256 lowerAmplitudesIndex = amplitudesLength - 1;
        while (lowerWave.length < lowerWaveWidth * 2) {
            uint256 gap = lowerWaveWidth * 2 - lowerWave.length;
            for (uint256 i = lowerAmplitudesIndex; i >= 0; i--) {
                if (gap >= lowerAmplitudes[i].length) {
                    lowerWave = abi.encodePacked(lowerWave, lowerAmplitudes[i]);
                    lowerAmplitudesIndex = i;
                    break;
                }
            }
        }

        uint256 adjustAmplitudesIndex = amplitudesLength - 1;
        while (adjustWave.length < adjustWaveWidth * 2) {
            uint256 gap = adjustWaveWidth * 2 - adjustWave.length;
            for (uint256 i = adjustAmplitudesIndex; i >= 0; i--) {
                if (gap >= upperAmplitudes[i].length) {
                    adjustWave = abi.encodePacked(
                        adjustWave,
                        upperAmplitudes[i]
                    );
                    adjustAmplitudesIndex = i;
                    break;
                }
            }
        }
        while (sampleRate * 2 >= data.length + waveWidth * 2) {
            data = abi.encodePacked(data, upperWave, lowerWave);
        }
        data = abi.encodePacked(data, adjustWave);
        return data;
    }

    function encode(bytes memory data) internal pure returns (bytes memory) {
        return abi.encodePacked(riffChunk(), fmtSubChunk(), dataSubChunk(data));
    }

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
}
