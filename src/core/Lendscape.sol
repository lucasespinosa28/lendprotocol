// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ILendscape} from "../interface/ILendscape.sol";
import {LendscapeStorage} from "./LendscapeStorage.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title Lendscape
 * @author Your Name
 * @notice This contract implements a peer-to-peer NFT-collateralized lending platform.
 * A borrower lists an NFT as collateral, and a lender funds the loan with ETH.
 */
contract Lendscape is ILendscape, LendscapeStorage, ReentrancyGuard {
    /**
     * @notice Sets the owner of the contract.
     */
    constructor() {
        owner = msg.sender;
    }

    /**
     * @notice Creates a loan request by putting an NFT up as collateral.
     * @param nftContract The address of the NFT contract.
     * @param tokenId The ID of the NFT being used as collateral.
     * @param loanAmount The amount of ETH the borrower wants to receive.
     * @param repaymentAmount The total amount of ETH to be repaid.
     * @param duration The duration of the loan in seconds.
     */
    function createLoanRequest(
        address nftContract,
        uint256 tokenId,
        uint256 loanAmount,
        uint256 repaymentAmount,
        uint256 duration
    ) external override nonReentrant {
        require(loanAmount > 0, "Loan amount must be positive");
        require(
            repaymentAmount > loanAmount,
            "Repayment must be greater than loan amount"
        );
        require(duration > 0, "Duration must be positive");
        require(
            IERC721(nftContract).ownerOf(tokenId) == msg.sender,
            "You are not the owner of this NFT"
        );

        // Transfer the NFT from the borrower to the contract to be held as collateral
        IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);

        loanCounter++;
        uint256 loanId = loanCounter;

        loans[loanId] = Loan({
            id: loanId,
            borrower: msg.sender,
            lender: address(0), // Lender is unknown until the loan is funded
            nftContract: nftContract,
            tokenId: tokenId,
            loanAmount: loanAmount,
            repaymentAmount: repaymentAmount,
            duration: duration,
            startTime: 0,
            funded: false,
            repaid: false
        });

        emit LoanRequested(
            loanId,
            msg.sender,
            nftContract,
            tokenId,
            loanAmount,
            repaymentAmount,
            duration
        );
    }

    /**
     * @notice Funds an existing loan request.
     * @param loanId The ID of the loan to fund.
     */
    function fundLoan(uint256 loanId) external payable override nonReentrant {
        Loan storage loan = loans[loanId];

        require(loan.borrower != address(0), "Loan does not exist");
        require(!loan.funded, "Loan has already been funded");
        require(
            msg.value == loan.loanAmount,
            "Incorrect ETH amount sent to fund loan"
        );

        loan.lender = msg.sender;
        loan.funded = true;
        loan.startTime = block.timestamp;

        // Send the loan amount to the borrower
        (bool success, ) = payable(loan.borrower).call{value: loan.loanAmount}(
            ""
        );
        require(success, "Failed to send ETH to borrower");

        emit LoanFunded(loanId, loan.borrower, loan.lender, loan.loanAmount);
    }

    /**
     * @notice Repays a funded loan to reclaim the NFT collateral.
     * @param loanId The ID of the loan to repay.
     */
    function repayLoan(uint256 loanId) external payable override nonReentrant {
        Loan storage loan = loans[loanId];

        require(loan.borrower == msg.sender, "You are not the borrower");
        require(loan.funded, "Loan is not funded");
        require(!loan.repaid, "Loan has already been repaid");
        require(
            msg.value == loan.repaymentAmount,
            "Incorrect ETH amount for repayment"
        );

        loan.repaid = true;

        // Send the repayment to the lender
        (bool success, ) = payable(loan.lender).call{
            value: loan.repaymentAmount
        }("");
        require(success, "Failed to send ETH to lender");

        // Return the NFT to the borrower
        IERC721(loan.nftContract).transferFrom(
            address(this),
            loan.borrower,
            loan.tokenId
        );

        emit LoanRepaid(loanId, loan.borrower, loan.repaymentAmount);
    }

    /**
     * @notice Liquidates an expired loan, giving the NFT to the lender.
     * @param loanId The ID of the loan to liquidate.
     */
    function liquidateLoan(uint256 loanId) external override nonReentrant {
        Loan storage loan = loans[loanId];

        require(loan.funded, "Loan is not funded");
        require(!loan.repaid, "Loan has already been repaid");
        require(
            block.timestamp >= loan.startTime + loan.duration,
            "Loan has not expired yet"
        );

        loan.repaid = true; // Mark as settled to prevent further actions

        // Transfer the NFT collateral to the lender
        IERC721(loan.nftContract).transferFrom(
            address(this),
            loan.lender,
            loan.tokenId
        );

        emit LoanLiquidated(loanId, loan.lender);
    }
}
