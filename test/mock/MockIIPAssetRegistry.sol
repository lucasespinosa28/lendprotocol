// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IIPAssetRegistry} from "protocol-core-v1/contracts/interfaces/registries/IIPAssetRegistry.sol";

contract MockIIPAssetRegistry is IIPAssetRegistry {
    mapping(address => bool) private _isRegistered;
    mapping(uint256 => mapping(address => mapping(uint256 => address))) private _ipIds;

    address private _treasury;
    address private _feeToken;
    uint96 private _feeAmount;
    uint256 private _totalSupply;
    address private _ipAccountImpl;

    function ipId(uint256 chainId, address tokenContract, uint256 tokenId) external view override returns (address) {
        return _ipIds[chainId][tokenContract][tokenId];
    }

    function isRegistered(address ipId) external view override returns (bool) {
        return _isRegistered[ipId];
    }

    function setIpId(uint256 chainId, address tokenContract, uint256 tokenId, address ipId) external {
        _ipIds[chainId][tokenContract][tokenId] = ipId;
    }

    function setRegistered(address ipId, bool registered) external {
        _isRegistered[ipId] = registered;
    }

    function attachLicense(address, address, uint256) external override {}
    function detachLicense(address, address, uint256) external override {}
    function parentIpId(address) external view override returns (address) { return address(0); }
    function rootIpId(address) external view override returns (address) { return address(0); }

    function register(
        uint256 chainId,
        address tokenContract,
        uint256 tokenId
    ) external override returns (address id) {
        // Mock: generate a pseudo-random address for the IP
        id = address(uint160(uint256(keccak256(abi.encodePacked(chainId, tokenContract, tokenId, block.timestamp)))));
        _ipIds[chainId][tokenContract][tokenId] = id;
        _isRegistered[id] = true;
        _totalSupply += 1;
        emit IPRegistered(id, chainId, tokenContract, tokenId, "", "", block.timestamp);
    }

    function register(
        uint256 chainId,
        address tokenContract,
        uint256 tokenId,
        string calldata,
        address
    ) external override returns (address) {
        // Mock: call the basic register
        return this.register(chainId, tokenContract, tokenId);
    }

    function setRegistrationFee(address treasury, address feeToken, uint96 feeAmount) external override {
        _treasury = treasury;
        _feeToken = feeToken;
        _feeAmount = feeAmount;
        emit RegistrationFeeSet(treasury, feeToken, feeAmount);
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function upgradeIPAccountImpl(address newIpAccountImpl) external override {
        _ipAccountImpl = newIpAccountImpl;
    }

    function getTreasury() external view override returns (address) {
        return _treasury;
    }

    function getFeeToken() external view override returns (address) {
        return _feeToken;
    }

    function getFeeAmount() external view override returns (uint96) {
        return _feeAmount;
    }
}