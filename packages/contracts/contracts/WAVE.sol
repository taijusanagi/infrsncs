//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./ByteSwapping.sol";

library WAVE {
    bytes4 constant chunkID = "RIFF";
    bytes4 constant format = "WAVE";
    bytes4 constant subchunk1ID = "fmt ";
    uint32 constant subchunk1Size = 16;
    uint16 constant audioFormat = 1;
    uint16 constant numChannels = 1;
    uint16 constant bitsPerSample = 16;
    bytes4 constant subchunk2ID = "data";

    int16 public constant upperAmplitude = 16383;
    int16 public constant lowerAmplitude = -16383;

    uint256 public constant maxSampleRate = 8000;
    uint256 public constant minSampleRate = 3000;

    uint256 public constant maxHertz = 16;
    uint256 public constant minHertz = 1;

    uint256 public constant maxDutyCycle = 99;
    uint256 public constant minDutyCycle = 1;
    uint256 public constant dutyCycleBase = 100;

    function generate(
        uint256 sampleRate,
        uint256 hertz,
        uint256 dutyCycle
    ) internal pure returns (bytes memory) {
        bytes memory data;

        uint256 waveWidth = sampleRate / hertz;
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

        for (uint256 i = 1; i < amplitudesLength; i++) {
            uint256 lastIndex = i - 1;
            upperAmplitudes[i] = abi.encodePacked(
                upperAmplitudes[lastIndex],
                upperAmplitudes[lastIndex]
            );
            lowerAmplitudes[i] = abi.encodePacked(
                lowerAmplitudes[lastIndex],
                lowerAmplitudes[lastIndex]
            );
        }

        uint256 upperWaveWidth = (waveWidth * dutyCycle) / dutyCycleBase;
        uint256 lowerWaveWidth = (waveWidth * (dutyCycleBase - dutyCycle)) /
            dutyCycleBase;
        uint256 adjustWaveWidth = sampleRate %
            (upperWaveWidth + lowerWaveWidth);

        bytes memory upperWave = concatAmplitudes(
            upperAmplitudes,
            upperWaveWidth
        );
        bytes memory lowerWave = concatAmplitudes(
            lowerAmplitudes,
            lowerWaveWidth
        );
        bytes memory adjustWave = concatAmplitudes(
            upperAmplitudes,
            adjustWaveWidth
        );

        while (sampleRate * 2 >= data.length + waveWidth * 2) {
            data = abi.encodePacked(data, upperWave, lowerWave);
        }
        data = abi.encodePacked(data, adjustWave);

        return encode(uint32(sampleRate), data);
    }

    function calculateSampleRate(uint256 seed) internal pure returns (uint256) {
        return ramdom(seed, maxSampleRate, minSampleRate);
    }

    function calculateHerts(uint256 seed) internal pure returns (uint256) {
        return ramdom(seed, maxHertz, minHertz);
    }

    function calculateDutyCycle(uint256 seed) internal pure returns (uint256) {
        return ramdom(seed, maxDutyCycle, minDutyCycle);
    }

    function ramdom(
        uint256 seed,
        uint256 max,
        uint256 min
    ) internal pure returns (uint256) {
        return (seed % (max - min)) + min;
    }

    function concatAmplitudes(bytes[] memory amplitudes, uint256 waveWidth)
        internal
        pure
        returns (bytes memory)
    {
        bytes memory concatedAmplitudes;
        uint256 lastAmplitudesIndex = amplitudes.length - 1;
        while (concatedAmplitudes.length < waveWidth * 2) {
            uint256 gap = waveWidth * 2 - concatedAmplitudes.length;
            for (uint256 i = lastAmplitudesIndex; i >= 0; i--) {
                if (gap >= amplitudes[i].length) {
                    concatedAmplitudes = abi.encodePacked(
                        concatedAmplitudes,
                        amplitudes[i]
                    );
                    lastAmplitudesIndex = i;
                    break;
                }
            }
        }
        return concatedAmplitudes;
    }

    function encode(uint32 sampleRate, bytes memory data)
        internal
        pure
        returns (bytes memory)
    {
        return
            abi.encodePacked(
                riffChunk(sampleRate),
                fmtSubChunk(sampleRate),
                dataSubChunk(sampleRate, data)
            );
    }

    function riffChunk(uint32 sampleRate) internal pure returns (bytes memory) {
        return
            abi.encodePacked(
                chunkID,
                ByteSwapping.swapUint32(chunkSize(sampleRate)),
                format
            );
    }

    function chunkSize(uint32 sampleRate) internal pure returns (uint32) {
        return 4 + (8 + subchunk1Size) + (8 + subchunk2Size(sampleRate));
    }

    function fmtSubChunk(uint32 sampleRate)
        internal
        pure
        returns (bytes memory)
    {
        return
            abi.encodePacked(
                subchunk1ID,
                ByteSwapping.swapUint32(subchunk1Size),
                ByteSwapping.swapUint16(audioFormat),
                ByteSwapping.swapUint16(numChannels),
                ByteSwapping.swapUint32(sampleRate),
                ByteSwapping.swapUint32(byteRate(sampleRate)),
                ByteSwapping.swapUint16(blockAlign()),
                ByteSwapping.swapUint16(bitsPerSample)
            );
    }

    function byteRate(uint32 sampleRate) internal pure returns (uint32) {
        return (sampleRate * numChannels * bitsPerSample) / 8;
    }

    function blockAlign() internal pure returns (uint16) {
        return (numChannels * bitsPerSample) / 8;
    }

    function dataSubChunk(uint32 sampleRate, bytes memory data)
        internal
        pure
        returns (bytes memory)
    {
        return
            abi.encodePacked(
                subchunk2ID,
                ByteSwapping.swapUint32(subchunk2Size(sampleRate)),
                data
            );
    }

    function subchunk2Size(uint32 sampleRate) internal pure returns (uint32) {
        return (sampleRate * numChannels * bitsPerSample) / 8;
    }
}
