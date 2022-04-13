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
    constructor(address _layerZeroEndpoint) {
        endpoint = ILayerZeroEndpoint(_layerZeroEndpoint);
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

    function transferOmnichainNFT(uint16 chainId, uint256 tokenId)
        public
        payable
    {
        require(
            msg.sender == ownerOf(tokenId),
            "Omnichain: Message sender must own the OmnichainNFT."
        );
        require(
            trustedSourceLookup[chainId].length != 0,
            "Omnichain: This chain is not a trusted source source."
        );

        bytes32 birthChainSeed = _getBirthChainSeed(tokenId);
        bytes32 tokenIdSeed = _getTokenIdSeed(tokenId);

        _burn(tokenId);

        bytes memory payload = abi.encode(
            msg.sender,
            tokenId,
            birthChainSeed,
            tokenIdSeed
        );
        uint16 version = 1;
        uint256 gas = 225000;
        bytes memory adapterParams = abi.encodePacked(version, gas);
        (uint256 quotedLayerZeroFee, ) = endpoint.estimateFees(
            chainId,
            address(this),
            payload,
            false,
            adapterParams
        );
        require(
            msg.value >= quotedLayerZeroFee,
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

    // solhint-disable-next-line func-name-mixedcase
    function _LzReceive(
        uint16 _srcChainId, // solhint-disable-line no-unused-vars
        bytes memory _srcAddress, // solhint-disable-line no-unused-vars
        uint64 _nonce, // solhint-disable-line no-unused-vars
        bytes memory payload
    ) internal override {
        (
            address dstOmnichainNFTAddress,
            uint256 omnichainNFTTokenId,
            bytes32 birthChainSeed,
            bytes32 tokenIdSeed
        ) = abi.decode(payload, (address, uint256, bytes32, bytes32));
        _safeMint(dstOmnichainNFTAddress, omnichainNFTTokenId);
        _registerTraverse(omnichainNFTTokenId, birthChainSeed, tokenIdSeed);
    }

    function _registerTraverse(
        uint256 tokenId,
        bytes32 birthChainSeed,
        bytes32 tokenIdSeed
    ) internal virtual;

    function _getBirthChainSeed(uint256 tokenId)
        internal
        view
        virtual
        returns (bytes32 birthChainSeed);

    function _getTokenIdSeed(uint256 tokenId)
        internal
        view
        virtual
        returns (bytes32 tokenIdSeed);
}
