// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {ILendscape} from "../interface/ILendscape.sol";
import {LendscapeStorage} from "./LendscapeStorage.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IIPAssetRegistry} from "protocol-core-v1/contracts/interfaces/registries/IIPAssetRegistry.sol";
import {IRoyaltyModule} from "protocol-core-v1/contracts/interfaces/modules/royalty/IRoyaltyModule.sol";
import {IIpRoyaltyVault} from "protocol-core-v1/contracts/interfaces/modules/royalty/policies/IIpRoyaltyVault.sol";
import {IIPAccount} from "protocol-core-v1/contracts/interfaces/IIPAccount.sol";

/**
 * @title Lendscape
 * @author Your Name
 * @notice This contract implements a peer-to-peer NFT-collateralized lending platform
 * that integrates with a royalty system using ERC20 tokens.
 */
contract Lendscape is ILendscape, LendscapeStorage, ReentrancyGuard {
    IRoyaltyModule public immutable royaltyModule;
    IIPAssetRegistry public immutable ipAssetRegistry;

    /**
     * @notice Sets the owner and the royalty module address.
     * @param _royaltyModuleAddress The address of the royalty module contract.
     * @param _ipAssetRegistryAddress The address of the IP Asset Registry contract.
     */
    constructor(address _royaltyModuleAddress, address _ipAssetRegistryAddress) {
        owner = msg.sender;
        royaltyModule = IRoyaltyModule(_royaltyModuleAddress);
        ipAssetRegistry = IIPAssetRegistry(_ipAssetRegistryAddress);
    }

    /**
     * @notice Creates a loan request by putting an NFT up as collateral.
     * @dev The NFT must be registered as an IP Asset on Story Protocol.
     * @param nftContract The address of the NFT contract.
     * @param tokenId The ID of the NFT being used as collateral.
     * @param loanToken The address of the ERC20 token to be used for the loan.
     * @param loanAmount The amount of the ERC20 token the borrower wants to receive.
     * @param repaymentAmount The total amount of the ERC20 token to be repaid.
     * @param duration The duration of the loan in seconds.
     */
    function createLoanRequest(
        address nftContract,
        uint256 tokenId,
        address loanToken,
        uint256 loanAmount,
        uint256 repaymentAmount,
        uint256 duration
    ) external override nonReentrant {
        require(loanAmount > 0, "Loan amount must be positive");
        require(repaymentAmount > loanAmount, "Repayment must be greater than loan amount");
        require(duration > 0, "Duration must be positive");
        require(IERC721(nftContract).ownerOf(tokenId) == msg.sender, "You are not the owner of this NFT");
        require(loanToken != address(0), "Invalid loan token address");

        address ipId = ipAssetRegistry.ipId(block.chainid, nftContract, tokenId);
        require(ipAssetRegistry.isRegistered(ipId), "NFT not registered as IP Asset");

        IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);

        loanCounter++;
        uint256 loanId = loanCounter;

        loans[loanId] = Loan({
            id: loanId,
            ipId: ipId,
            borrower: msg.sender,
            lender: address(0),
            nftContract: nftContract,
            tokenId: tokenId,
            loanToken: loanToken,
            loanAmount: loanAmount,
            repaymentAmount: repaymentAmount,
            duration: duration,
            startTime: 0,
            funded: false,
            repaid: false
        });

        emit LoanRequested(
            loanId, ipId, msg.sender, nftContract, tokenId, loanToken, loanAmount, repaymentAmount, duration
        );
    }

    /**
     * @notice Funds an existing loan request. The lender must approve the contract to spend the loan amount first.
     * @param loanId The ID of the loan to fund.
     */
    function fundLoan(uint256 loanId) external override nonReentrant {
        Loan storage loan = loans[loanId];

        require(loan.borrower != address(0), "Loan does not exist");
        require(!loan.funded, "Loan has already been funded");

        IERC20(loan.loanToken).transferFrom(msg.sender, address(this), loan.loanAmount);

        loan.lender = msg.sender;
        loan.funded = true;
        loan.startTime = block.timestamp;

        IERC20(loan.loanToken).transfer(loan.borrower, loan.loanAmount);

        emit LoanFunded(loanId, loan.ipId, loan.borrower, loan.lender, loan.loanAmount);
    }

    /**
     * @notice Repays a funded loan to reclaim the NFT collateral.
     * @dev The borrower must approve the contract to spend the necessary amount of tokens.
     * @param loanId The ID of the loan to repay.
     */
    function repayLoan(uint256 loanId) external override nonReentrant {
        Loan storage loan = loans[loanId];

        require(loan.borrower == msg.sender, "You are not the borrower");
        require(loan.funded, "Loan is not funded");
        require(!loan.repaid, "Loan has already been repaid");

        address ipId = loan.ipId;
        address vaultAddress = royaltyModule.ipRoyaltyVaults(ipId);
        uint256 claimableRoyalty = 0; //hange everywhere you call

        if (vaultAddress != address(0)) {
            claimableRoyalty = IIpRoyaltyVault(vaultAddress).claimableRevenue(ipId, loan.loanToken);
        }

        uint256 amountFromWallet;
        if (claimableRoyalty < loan.repaymentAmount) {
            amountFromWallet = loan.repaymentAmount - claimableRoyalty;
        }

        if (amountFromWallet > 0) {
            IERC20(loan.loanToken).transferFrom(msg.sender, address(this), amountFromWallet);
        }

        if (claimableRoyalty > 0) {
            uint256 claimedAmount = IIpRoyaltyVault(vaultAddress).claimRevenueOnBehalf(ipId, loan.loanToken);
            bytes memory callData = abi.encodeWithSignature("transfer(address,uint256)", address(this), claimedAmount);
            IIPAccount(payable(ipId)).execute(loan.loanToken, 0, callData);
        }

        uint256 amountToRepay = amountFromWallet + claimableRoyalty;
        require(amountToRepay >= loan.repaymentAmount, "Insufficient funds to repay loan");

        IERC20(loan.loanToken).transfer(loan.lender, loan.repaymentAmount);
        if (amountToRepay > loan.repaymentAmount) {
            IERC20(loan.loanToken).transfer(loan.borrower, amountToRepay - loan.repaymentAmount);
        }

        IERC721(loan.nftContract).transferFrom(address(this), loan.borrower, loan.tokenId);

        loan.repaid = true;
        loan.funded = false;

        emit LoanRepaid(loanId, ipId, loan.borrower, loan.repaymentAmount);
    }

    /**
     * @notice Liquidates an expired loan. If royalties cover the loan, the lender gets paid and borrower gets the NFT back.
     * Otherwise, the lender gets any available royalties plus the NFT.
     * @param loanId The ID of the loan to liquidate.
     */
    function liquidateLoan(uint256 loanId) external override nonReentrant {
        Loan storage loan = loans[loanId];

        require(loan.funded, "Loan is not funded");
        require(!loan.repaid, "Loan has already been repaid");
        require(block.timestamp >= loan.startTime + loan.duration, "Loan has not expired yet");

        address ipId = loan.ipId;
        address vaultAddress = royaltyModule.ipRoyaltyVaults(ipId);
        uint256 claimableRoyalty = 0;

        if (vaultAddress != address(0)) {
            claimableRoyalty = IIpRoyaltyVault(vaultAddress).claimableRevenue(ipId, loan.loanToken);
        }

        if (claimableRoyalty >= loan.repaymentAmount) {
            uint256 claimedAmount = IIpRoyaltyVault(vaultAddress).claimRevenueOnBehalf(ipId, loan.loanToken);
            bytes memory callData = abi.encodeWithSignature("transfer(address,uint256)", address(this), claimedAmount);
            IIPAccount(payable(ipId)).execute(loan.loanToken, 0, callData);

            IERC20(loan.loanToken).transfer(loan.lender, loan.repaymentAmount);

            if (claimedAmount > loan.repaymentAmount) {
                IERC20(loan.loanToken).transfer(loan.borrower, claimedAmount - loan.repaymentAmount);
            }

            IERC721(loan.nftContract).transferFrom(address(this), loan.borrower, loan.tokenId);
            emit LoanRepaid(loanId, ipId, loan.borrower, loan.repaymentAmount);
        } else {
            if (claimableRoyalty > 0) {
                uint256 claimedAmount = IIpRoyaltyVault(vaultAddress).claimRevenueOnBehalf(ipId, loan.loanToken);
                bytes memory callData =
                    abi.encodeWithSignature("transfer(address,uint256)", address(this), claimedAmount);
                IIPAccount(payable(ipId)).execute(loan.loanToken, 0, callData);
                IERC20(loan.loanToken).transfer(loan.lender, claimableRoyalty);
            }
            IERC721(loan.nftContract).transferFrom(address(this), loan.lender, loan.tokenId);
            emit LoanLiquidated(loanId, ipId, loan.lender);
        }

        loan.repaid = true;
        loan.funded = false;
    }
}
