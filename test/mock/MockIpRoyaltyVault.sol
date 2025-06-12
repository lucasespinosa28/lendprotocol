// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IIpRoyaltyVault} from "protocol-core-v1/contracts/interfaces/modules/royalty/policies/IIpRoyaltyVault.sol";

contract MockIpRoyaltyVault is IIpRoyaltyVault {
    mapping(address => mapping(address => uint256)) public revenues;
    address private _ipId;
    address[] private _tokens;
    mapping(address => uint256) private _vaultAccBalances;
    mapping(address => mapping(address => int256)) private _claimerRevenueDebt;

    function setClaimableRevenue(address claimer, address token, uint256 amount) external {
        revenues[claimer][token] = amount;
    }

    function claimableRevenue(address claimer, address token) external view override returns (uint256) {
        return revenues[claimer][token];
    }

    function claimRevenueOnBehalf(address claimer, address token) external override returns (uint256 amount) {
        amount = revenues[claimer][token];
        revenues[claimer][token] = 0;
        emit RevenueTokenClaimed(claimer, token, amount);
    }

    function claimableRevenueOnBehalf(address, address, address) external pure override returns (uint256) {
        return 0;
    }

    function snapshot() external pure override returns (uint256) {
        return 0;
    }

    function onTokenTransfer(address, address, uint256) external pure override returns (bool) {
        return true;
    }

    function supportsInterface(bytes4) external pure override returns (bool) {
        return true;
    }

    function initialize(
        string memory,
        string memory,
        uint32,
        address ipIdAddress,
        address
    ) external override {
        _ipId = ipIdAddress;
    }

    function updateVaultBalance(address token, uint256 amount) external override {
        _vaultAccBalances[token] += amount;
        bool exists = false;
        for (uint256 i = 0; i < _tokens.length; i++) {
            if (_tokens[i] == token) {
                exists = true;
                break;
            }
        }
        if (!exists) {
            _tokens.push(token);
        }
        emit RevenueTokenAddedToVault(token, amount);
    }

    function claimRevenueOnBehalfByTokenBatch(
        address claimer,
        address[] calldata tokenList
    ) external override returns (uint256[] memory amounts) {
        amounts = new uint256[](tokenList.length);
        for (uint256 i = 0; i < tokenList.length; i++) {
            amounts[i] = revenues[claimer][tokenList[i]];
            revenues[claimer][tokenList[i]] = 0;
            emit RevenueTokenClaimed(claimer, tokenList[i], amounts[i]);
        }
    }

    function claimByTokenBatchAsSelf(address[] calldata, address) external pure override {}

    function ipId() external view override returns (address) {
        return _ipId;
    }

    function tokens() external view override returns (address[] memory) {
        return _tokens;
    }

    function vaultAccBalances(address token) external view override returns (uint256) {
        return _vaultAccBalances[token];
    }

    function claimerRevenueDebt(address claimer, address token) external view override returns (int256) {
        return _claimerRevenueDebt[claimer][token];
    }
}