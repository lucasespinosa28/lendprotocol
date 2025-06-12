// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IRoyaltyModule {
    function claimableRevenue(
        address royaltyVaultIpId,
        address claimer,
        address token
    ) external view returns (uint256);

    function claimAllRevenue(
        address ancestorIpId,
        address claimer,
        address[] calldata currencyTokens,
        address[] calldata childIpIds,
        address[] calldata royaltyPolicies
    ) external returns (uint256[] memory claimedTokens);
}

contract MockRoyaltyModule is IRoyaltyModule {
    mapping(address => uint256) public revenues;

    function setClaimableRevenue(address ipId, uint256 amount) public {
        revenues[ipId] = amount;
    }

    function claimableRevenue(
        address royaltyVaultIpId,
        address, // claimer
        address // token
    ) external view returns (uint256) {
        return revenues[royaltyVaultIpId];
    }

    function claimAllRevenue(
        address, // ancestorIpId
        address, // claimer
        address[] calldata, // currencyTokens
        address[] calldata, // childIpIds
        address[] calldata // royaltyPolicies
    ) external returns (uint256[] memory) {
        // This is a mock and doesn't need to do anything.
        return new uint256[](0);
    }
}
