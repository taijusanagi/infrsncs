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

    function transferOmnichainNFT(uint16 _chainId, uint256 omniChainNFT_tokenId)
        public
        payable
    {
        require(
            msg.sender == ownerOf(omniChainNFT_tokenId),
            "Omnichain: Message sender must own the OmnichainNFT."
        );
        require(
            trustedSourceLookup[_chainId].length != 0,
            "Omnichain: This chain is not a trusted source source."
        );

        _burn(omniChainNFT_tokenId);

        bytes memory payload = abi.encode(msg.sender, omniChainNFT_tokenId);
        uint16 version = 1;
        uint256 gas = 225000;
        bytes memory adapterParams = abi.encodePacked(version, gas);
        (uint256 quotedLayerZeroFee, ) = endpoint.estimateFees(
            _chainId,
            address(this),
            payload,
            false,
            adapterParams
        );
        require(
            msg.value >= quotedLayerZeroFee,
            "Omnichain: Not enough gas to cover cross chain transfer."
        );

        endpoint.send{value: msg.value}(
            _chainId,
            trustedSourceLookup[_chainId],
            payload,
            payable(msg.sender),
            address(0x0),
            adapterParams
        );
    }

    function _LzReceive(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint64 _nonce,
        bytes memory _payload
    ) internal override {
        (address _dstOmnichainNFTAddress, uint256 omnichainNFTTokenId) = abi
            .decode(_payload, (address, uint256));

        _safeMint(_dstOmnichainNFTAddress, omnichainNFTTokenId);
    }

    function setConfig(
        uint16 _version,
        uint16 _chainId,
        uint256 _configType,
        bytes calldata _config
    ) external override onlyOwner {
        endpoint.setConfig(_version, _chainId, _configType, _config);
    }

    function setSendVersion(uint16 _version) external override onlyOwner {
        endpoint.setSendVersion(_version);
    }

    function setReceiveVersion(uint16 _version) external override onlyOwner {
        endpoint.setReceiveVersion(_version);
    }

    function forceResumeReceive(uint16 _srcChainId, bytes calldata _srcAddress)
        external
        override
        onlyOwner
    {
        endpoint.forceResumeReceive(_srcChainId, _srcAddress);
    }
}
