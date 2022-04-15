//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

import "./ByteSwapping.sol";
import "./SVG.sol";
import "./Traversable.sol";
import "./WAVE.sol";

contract ChainBeats is ERC721, Ownable, Traversable {
    uint256 public genesisBlockHash;
    uint256 public supplied;
    uint256 public startTokenId;
    uint256 public endTokenId;
    uint256 public mintPrice;

    constructor(
        address layerZeroEndpoint,
        uint256 genesisBlockHash_,
        uint256 startTokenId_,
        uint256 endTokenId_,
        uint256 mintPrice_
    ) ERC721("ChainBeats", "CB") Traversable(layerZeroEndpoint) {
        genesisBlockHash = genesisBlockHash_;
        startTokenId = startTokenId_;
        endTokenId = endTokenId_;
        mintPrice = mintPrice_;
    }

    //solhint-disable-next-line no-empty-blocks
    function donate() public payable {
        // thank you
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function mint(address to) public payable virtual {
        require(msg.value >= mintPrice, "ChainBeats: msg value invalid");
        uint256 tokenId = startTokenId + supplied;
        require(tokenId <= endTokenId, "ChainBeats: mint finished");
        _safeMint(to, tokenId);
        _registerTraversableSeeds(
            tokenId,
            genesisBlockHash,
            uint256(
                keccak256(
                    abi.encodePacked(blockhash(block.number - 1), tokenId)
                )
            )
        );
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
        (uint256 birthChainSeed, uint256 tokenIdSeed) = _getTraversableSeeds(
            tokenId
        );
        uint256 sampleRate = WAVE.calculateSampleRate(genesisBlockHash);
        uint256 dutyCycle = WAVE.calculateDutyCycle(birthChainSeed);
        uint256 waveWidth = WAVE.calculateWaveWidth(sampleRate, tokenIdSeed);
        bytes memory wave = WAVE.generate(sampleRate, waveWidth, dutyCycle);
        bytes memory metadata = abi.encodePacked(
            '{"name":"ChainBeats #',
            Strings.toString(tokenId),
            '","description": "A unique beat represented entirely on-chain.","image_data":"',
            SVG.generate(wave),
            '","animation_url":"',
            wave,
            '","attributes":',
            abi.encodePacked(
                '[{"trait_type":"SAMPLE RATE","value":"',
                Strings.toString(sampleRate),
                '"},{"trait_type":"DUTY CYCLE","value":"',
                Strings.toString(dutyCycle),
                '"},{"trait_type":"WAVE WIDTH","value":"',
                Strings.toString(waveWidth),
                '"},{"trait_type":"APPROXIMATE HERTZ","value":"',
                Strings.toString(sampleRate / waveWidth),
                '"},{"trait_type":"BIRTH CHAIN SEED","value":"',
                Strings.toHexString(birthChainSeed, 32),
                '"},{"trait_type":"TOKEN ID SEED","value":"',
                Strings.toHexString(tokenIdSeed, 32),
                '"}]'
            ),
            "}"
        );
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(metadata)
                )
            );
    }
}
