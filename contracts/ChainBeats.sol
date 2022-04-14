//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

import "solidity-examples/contracts/NonBlockingReceiver.sol";
import "solidity-examples/contracts/interfaces/ILayerZeroEndpoint.sol";
import "solidity-examples/contracts/interfaces/ILayerZeroUserApplicationConfig.sol";

import "./ByteSwapping.sol";
import "./SVG.sol";
import "./Omnichain.sol";
import "./WAVE.sol";

contract ChainBeats is ERC721, Ownable, Omnichain {
    uint256 public supplied;
    uint256 public startTokenId;
    uint256 public endTokenId;
    uint256 public mintPrice;

    constructor(
        address layerZeroEndpoint,
        uint256 startTokenId_,
        uint256 endTokenId_,
        uint256 mintPrice_,
        uint256 gasForDestinationLzReceive_,
        bytes32 birthChainGenesisBlockHash_
    )
        ERC721("ChainBeats", "CB")
        Omnichain(
            layerZeroEndpoint,
            gasForDestinationLzReceive_,
            birthChainGenesisBlockHash_
        )
    {
        startTokenId = startTokenId_;
        endTokenId = endTokenId_;
        mintPrice = mintPrice_;
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
            birthChainGenesisBlockHash,
            keccak256(abi.encodePacked(blockhash(block.number - 1), tokenId))
        );
        supplied++;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory tokenURI_)
    {
        require(_exists(tokenId), "ChainBeats: nonexistent token");
        (bytes32 birthChainSeed, bytes32 tokenIdSeed) = getTraversableSeeds(
            tokenId
        );
        uint256 sampleRate = WAVE.calculateSampleRate(uint256(birthChainSeed));
        uint256 hertz = WAVE.calculateHertz(uint256(tokenIdSeed));
        uint256 dutyCycle = WAVE.calculateDutyCycle(uint256(tokenIdSeed));
        bytes memory wave = WAVE.generate(sampleRate, hertz, dutyCycle);
        bytes memory svg = SVG.generate(wave);
        bytes memory metadata = abi.encodePacked(
            "{",
            '"name":"ChainBeats #',
            Strings.toString(tokenId),
            '","description": "A unique beat represented entirely on-chain."',
            ',"image":"',
            svg,
            '","animation_url":"',
            wave,
            '","attributes":',
            abi.encodePacked(
                "[{",
                '"trait_type":"SAMPLE RATE","value":"',
                Strings.toString(sampleRate),
                '"},{',
                '"trait_type":"HERTS","value":"',
                Strings.toString(hertz),
                '"},{',
                '"trait_type":"DUTY CYCLE","value":"',
                Strings.toString(dutyCycle),
                '"},{',
                '"trait_type":"BIRTH CHAIN SEED","value":"',
                Strings.toHexString(uint256(birthChainSeed), 32),
                '"},{',
                '"trait_type":"TOKEN ID SEED","value":"',
                Strings.toHexString(uint256(tokenIdSeed), 32),
                '"}]'
            ),
            "}"
        );
        tokenURI_ = string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(metadata)
            )
        );
    }
}
