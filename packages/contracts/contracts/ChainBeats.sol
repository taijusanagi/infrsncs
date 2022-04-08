//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

import "./ByteSwapping.sol";
import "./Sound.sol";
import "./Image.sol";

contract ChainBeats is ERC721 {
    using Counters for Counters.Counter;
    using Strings for uint256;
    using Base64 for bytes;

    Counters.Counter private _tokenIdTracker;

    mapping(uint256 => bytes32) public seeds;

    uint256 public constant supplyLimit = 1000;
    uint256 public constant mintPrice = 0.02 ether;

    constructor() ERC721("ChainBeats", "CB") {}

    function mint(address to) public payable virtual {
        require(msg.value == mintPrice, "ChainBeats: msg value is invalid");
        uint256 tokenId = _tokenIdTracker.current();
        require(tokenId < supplyLimit, "ChainBeats: mint is already finished");
        seeds[tokenId] = keccak256(
            abi.encodePacked(
                block.chainid,
                blockhash(0),
                blockhash(block.number - 1),
                block.timestamp,
                tokenId
            )
        );
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
        bytes memory sound = Sound.getSound(seeds[tokenId]);
        bytes memory audioDataURI = abi.encodePacked(
            "data:audio/wav;base64,",
            Sound.encode(sound).encode()
        );
        bytes memory svg = Image.generateSVG(sound);
        return
            abi.encodePacked(
                '{"name": "Sound #',
                tokenId.toString(),
                '", "description": "A unique piece of sound represented entirely on-chain.',
                '", "image": "',
                svg,
                '", "animation_url": "',
                audioDataURI,
                '"}'
            );
    }
}
