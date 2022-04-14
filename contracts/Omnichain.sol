//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "solidity-examples/contracts/NonBlockingReceiver.sol";
import "solidity-examples/contracts/interfaces/ILayerZeroEndpoint.sol";
import "solidity-examples/contracts/interfaces/ILayerZeroUserApplicationConfig.sol";

abstract contract Omnichain is
    ERC721,
    Ownable,
    NonblockingReceiver,
    ILayerZeroUserApplicationConfig
{
    uint256 public gasForDestinationLzReceive;

    mapping(uint256 => uint256) private _birthChainSeeds;
    mapping(uint256 => uint256) private _tokenIdSeeds;

    constructor(address layerZeroEndpoint, uint256 gasForDestinationLzReceive_)
    {
        endpoint = ILayerZeroEndpoint(layerZeroEndpoint);
        gasForDestinationLzReceive = gasForDestinationLzReceive_;
    }

    function setConfig(
        uint16 version,
        uint16 chainId,
        uint256 configType,
        bytes calldata config
    ) external override onlyOwner {
        endpoint.setConfig(version, chainId, configType, config);
    }

    function setSendVersion(uint16 version) external override onlyOwner {
        endpoint.setSendVersion(version);
    }

    function setReceiveVersion(uint16 version) external override onlyOwner {
        endpoint.setReceiveVersion(version);
    }

    function forceResumeReceive(uint16 srcChainId, bytes calldata srcAddress)
        external
        override
        onlyOwner
    {
        endpoint.forceResumeReceive(srcChainId, srcAddress);
    }

    function setGasForDestinationLzReceive(uint256 gasForDestinationLzReceive_)
        external
        onlyOwner
    {
        gasForDestinationLzReceive = gasForDestinationLzReceive_;
    }

    function traverseChains(uint16 chainId, uint256 tokenId) public payable {
        require(
            msg.sender == ownerOf(tokenId),
            "Omnichain: Message sender must own the OmnichainNFT"
        );
        require(
            trustedSourceLookup[chainId].length != 0,
            "Omnichain: This chain is not a trusted source"
        );

        _unregisterTraversableSeeds(tokenId);
        _burn(tokenId);

        (uint256 birthChainSeed, uint256 tokenIdSeed) = _getTraversableSeeds(
            tokenId
        );
        bytes memory payload = abi.encode(
            msg.sender,
            tokenId,
            birthChainSeed,
            tokenIdSeed
        );
        uint16 version = 1;
        bytes memory adapterParams = abi.encodePacked(
            version,
            gasForDestinationLzReceive
        );
        (uint256 messageFee, ) = endpoint.estimateFees(
            chainId,
            address(this),
            payload,
            false,
            adapterParams
        );
        require(
            msg.value >= messageFee,
            "Omnichain: Not enough gas to cover cross chain transfer."
        );

        // solhint-disable-next-line check-send-result
        endpoint.send{value: msg.value}(
            chainId,
            trustedSourceLookup[chainId],
            payload,
            payable(msg.sender),
            address(0x0),
            adapterParams
        );
    }

    function _registerTraversableSeeds(
        uint256 tokenId,
        uint256 birthChainSeed,
        uint256 tokenIdSeed
    ) internal {
        _birthChainSeeds[tokenId] = birthChainSeed;
        _tokenIdSeeds[tokenId] = tokenIdSeed;
    }

    function _unregisterTraversableSeeds(uint256 tokenId) internal {
        delete _birthChainSeeds[tokenId];
        delete _tokenIdSeeds[tokenId];
    }

    // solhint-disable-next-line func-name-mixedcase
    function _LzReceive(
        uint16 _srcChainId, // solhint-disable-line no-unused-vars
        bytes memory _srcAddress, // solhint-disable-line no-unused-vars
        uint64 _nonce, // solhint-disable-line no-unused-vars
        bytes memory payload
    ) internal override {
        (
            address to,
            uint256 tokenId,
            uint256 birthChainSeed,
            uint256 tokenIdSeed
        ) = abi.decode(payload, (address, uint256, uint256, uint256));
        _safeMint(to, tokenId);
        _registerTraversableSeeds(tokenId, birthChainSeed, tokenIdSeed);
    }

    function _getTraversableSeeds(uint256 tokenId)
        internal
        view
        returns (uint256 birthChainSeed, uint256 tokenIdSeed)
    {
        return (_birthChainSeeds[tokenId], _tokenIdSeeds[tokenId]);
    }
}
