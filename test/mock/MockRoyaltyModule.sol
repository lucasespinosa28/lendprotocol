// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IRoyaltyModule} from "protocol-core-v1/contracts/interfaces/modules/royalty/IRoyaltyModule.sol";

contract MockRoyaltyModule is IRoyaltyModule {
    address private _treasury;
    uint32 private _royaltyFeePercent;
    uint256 private _maxParents;
    uint256 private _maxAncestors;
    uint256 private _maxAccumulatedRoyaltyPolicies;
    mapping(address => bool) private _whitelistedRoyaltyPolicies;
    mapping(address => bool) private _registeredExternalRoyaltyPolicies;
    mapping(address => bool) private _whitelistedRoyaltyTokens;
    mapping(address => bool) private _isIpRoyaltyVault;
    mapping(address => address) private _ipRoyaltyVaults;
    mapping(address => uint32) private _globalRoyaltyStack;
    mapping(address => address[]) private _accumulatedRoyaltyPolicies;
    mapping(address => mapping(address => uint256)) private _totalRevenueTokensReceived;
    mapping(address => mapping(address => mapping(address => uint256))) private _totalRevenueTokensAccounted;

    function name() external pure override returns (string memory) {
        return "MockRoyaltyModule";
    }

    function setTreasury(address treasury) external override {
        _treasury = treasury;
        emit TreasurySet(treasury);
    }

    function setRoyaltyFeePercent(uint32 royaltyFeePercent) external override {
        _royaltyFeePercent = royaltyFeePercent;
        emit RoyaltyFeePercentSet(royaltyFeePercent);
    }

    function setRoyaltyLimits(uint256 accumulatedRoyaltyPoliciesLimit) external override {
        _maxAccumulatedRoyaltyPolicies = accumulatedRoyaltyPoliciesLimit;
        emit RoyaltyLimitsUpdated(accumulatedRoyaltyPoliciesLimit);
    }

    function whitelistRoyaltyPolicy(address royaltyPolicy, bool allowed) external override {
        _whitelistedRoyaltyPolicies[royaltyPolicy] = allowed;
        emit RoyaltyPolicyWhitelistUpdated(royaltyPolicy, allowed);
    }

    function whitelistRoyaltyToken(address token, bool allowed) external override {
        _whitelistedRoyaltyTokens[token] = allowed;
        emit RoyaltyTokenWhitelistUpdated(token, allowed);
    }

    function registerExternalRoyaltyPolicy(address externalRoyaltyPolicy) external override {
        _registeredExternalRoyaltyPolicies[externalRoyaltyPolicy] = true;
        emit ExternalRoyaltyPolicyRegistered(externalRoyaltyPolicy);
    }

    function onLicenseMinting(address, address, uint32, bytes calldata) external pure override {}

    function onLinkToParents(address, address[] calldata, address[] calldata, uint32[] calldata, bytes calldata, uint32)
        external
        pure
        override
    {}

    function payRoyaltyOnBehalf(address, address, address, uint256) external pure override {}

    function payLicenseMintingFee(address, address, address, uint256) external pure override {}

    function hasAncestorIp(address, address) external pure override returns (bool) {
        return false;
    }

    function maxPercent() external pure override returns (uint32) {
        return 100_0000;
    }

    function treasury() external view override returns (address) {
        return _treasury;
    }

    function royaltyFeePercent() external view override returns (uint32) {
        return _royaltyFeePercent;
    }

    function maxParents() external view override returns (uint256) {
        return _maxParents;
    }

    function maxAncestors() external view override returns (uint256) {
        return _maxAncestors;
    }

    function maxAccumulatedRoyaltyPolicies() external view override returns (uint256) {
        return _maxAccumulatedRoyaltyPolicies;
    }

    function isWhitelistedRoyaltyPolicy(address royaltyPolicy) external view override returns (bool) {
        return _whitelistedRoyaltyPolicies[royaltyPolicy];
    }

    function isRegisteredExternalRoyaltyPolicy(address externalRoyaltyPolicy) external view override returns (bool) {
        return _registeredExternalRoyaltyPolicies[externalRoyaltyPolicy];
    }

    function isWhitelistedRoyaltyToken(address token) external view override returns (bool) {
        return _whitelistedRoyaltyTokens[token];
    }

    function isIpRoyaltyVault(address ipRoyaltyVault) external view override returns (bool) {
        return _isIpRoyaltyVault[ipRoyaltyVault];
    }

    function ipRoyaltyVaults(address ipId) external view override returns (address) {
        return _ipRoyaltyVaults[ipId];
    }

    function globalRoyaltyStack(address ipId) external view override returns (uint32) {
        return _globalRoyaltyStack[ipId];
    }

    function accumulatedRoyaltyPolicies(address ipId) external view override returns (address[] memory) {
        return _accumulatedRoyaltyPolicies[ipId];
    }

    function totalRevenueTokensReceived(address ipId, address token) external view override returns (uint256) {
        return _totalRevenueTokensReceived[ipId][token];
    }

    function totalRevenueTokensAccounted(address ipId, address token, address royaltyPolicy)
        external
        view
        override
        returns (uint256)
    {
        return _totalRevenueTokensAccounted[ipId][token][royaltyPolicy];
    }

    function supportsInterface(bytes4) external pure override returns (bool) {
        return true;
    }

    function setIpRoyaltyVault(address ipId, address vault) external {
        _ipRoyaltyVaults[ipId] = vault;
        _isIpRoyaltyVault[vault] = true;
    }
}
