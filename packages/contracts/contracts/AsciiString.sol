//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

library AsciiString {
    function toAsciiString(bytes memory input)
        internal
        pure
        returns (string memory)
    {
        bytes memory alphabet = "0123456789abcdef";
        bytes memory output = new bytes(input.length * 2);
        for (uint256 i = 0; i < input.length; i++) {
            uint256 index = i * 2;
            output[index] = alphabet[uint256(uint8(input[i] >> 4))];
            output[index + 1] = alphabet[uint256(uint8(input[i] & 0x0f))];
        }
        return string(output);
    }
}
