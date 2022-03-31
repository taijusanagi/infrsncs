//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

contract Noise is ERC721 {
    using Counters for Counters.Counter;
    using Strings for uint256;
    using Base64 for bytes;

    Counters.Counter private _tokenIdTracker;

    mapping(uint256 => bytes32) public seeds;

    string public imageUrlBase;
    string public animationUrlBase;

    constructor() ERC721("Noise", "NOISE") {}

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "Noise: URI query for nonexistent token");

        string memory html = getHTML();
        bytes memory metadata = getMetadata(tokenId, html);
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
        bytes32 seed = bytes32(uint256(uint160(to)) << 96);
        seeds[tokenId] = seed;
        _mint(to, tokenId);
        _tokenIdTracker.increment();
    }

    function getHTML() public pure returns (string memory) {
        string memory js = abi
            .encodePacked(
                'document.getElementById("myButton").addEventListener("click", clicked);function clicked() {console.log("hi");}'
            )
            .encode();

        return
            string(
                abi.encodePacked(
                    '<!doctype html><html lang="en"><body><script type="text/javascript" src="data:text/javascript;charset=utf-8;base64,',
                    js,
                    '"></script><h1 id="myButton">Hello, World!</h1></body></html>'
                )
            );
    }

    function getMetadata(uint256 tokenId, string memory html)
        public
        pure
        returns (bytes memory)
    {
        return
            abi.encodePacked(
                '{"name": "Noise #',
                tokenId.toString(),
                '", "description": "A unique piece of noise represented entirely on-chain.',
                '", "animation_url": "data:text/html;base64,',
                abi.encodePacked(html).encode(),
                '"}'
            );
    }
}
