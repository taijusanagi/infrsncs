//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

library AsciiString {
    function toAsciiString(bytes memory input)
        internal
        pure
        returns (string memory output)
    {
        bytes memory alphabet = "0123456789abcdef";
        bytes memory temp = new bytes(2 + input.length * 2);
        temp[0] = "0";
        temp[1] = "x";
        for (uint256 i = 0; i < input.length; i++) {
            temp[2 + i * 2] = alphabet[uint256(uint8(input[i] >> 4))];
            temp[3 + i * 2] = alphabet[uint256(uint8(input[i] & 0x0f))];
        }
        output = string(temp);
    }
}
