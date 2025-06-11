// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ILendscape} from "./ILendscape.sol";
import {LendscapeStorage} from "./LendscapeStorage.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title Lendscape
 * @author Your Name
 * @notice This contract implements the core functionality of the Lendscape NFT lending and borrowing platform.
 */
contract Lendscape is ILendscape, LendscapeStorage, ReentrancyGuard {
    /**
     * @notice Sets the owner of the contract.
     */
    constructor() {
        owner = msg.sender;
    }

    /**
     * @notice Lists an NFT for lending.
     * @param nftContract The address of the NFT contract.
     * @param tokenId The ID of the NFT.
     * @param loanAmount The amount of the loan.
     * @param interestRate The interest rate of the loan.
     * @param duration The duration of the loan.
     */
    function listNFT(
        address nftContract,
        uint256 tokenId,
        uint256 loanAmount,
        uint256 interestRate,
        uint256 duration
    ) external override nonReentrant {
        require(loanAmount > 0, "Loan amount must be greater than 0");
        require(interestRate > 0, "Interest rate must be greater than 0");
        require(duration > 0, "Duration must be greater than 0");

        IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);

        loanCounter++;
        uint256 loanId = loanCounter;

        loans[loanId] = Loan({
            id: loanId,
            lender: msg.sender,
            borrower: address(0),
            nftContract: nftContract,
            tokenId: tokenId,
            loanAmount: loanAmount,
            interestRate: interestRate,
            duration: duration,
            startTime: 0,
            active: true,
            repaid: false
        });

        users[msg.sender].lentNFTs.push(loanId);

        emit NFTListed(
            loanId,
            msg.sender,
            nftContract,
            tokenId,
            loanAmount,
            interestRate,
            duration
        );
    }

    /**
     * @notice Borrows an NFT.
     * @param loanId The ID of the loan.
     */
    function borrowNFT(uint256 loanId) external payable override nonReentrant {
        Loan storage loan = loans[loanId];

        require(loan.active, "Loan is not active");
        require(loan.borrower == address(0), "Loan has already been borrowed");
        require(msg.value >= loan.loanAmount, "Not enough collateral");

        loan.borrower = msg.sender;
        loan.startTime = block.timestamp;

        users[msg.sender].borrowedNFTs.push(loanId);

        emit LoanCreated(
            loanId,
            loan.lender,
            loan.borrower,
            loan.nftContract,
            loan.tokenId,
            loan.loanAmount,
            loan.interestRate,
            loan.duration
        );
    }

    /**
     * @notice Repays a loan.
     * @param loanId The ID of the loan.
     */
    function repayLoan(uint256 loanId) external payable override nonReentrant {
        Loan storage loan = loans[loanId];

        require(loan.borrower == msg.sender, "You are not the borrower");
        require(loan.active, "Loan is not active");

        uint256 interest = calculateInterest(loanId);
        uint256 totalAmount = loan.loanAmount + interest;

        require(msg.value >= totalAmount, "Not enough funds to repay loan");

        loan.active = false;
        loan.repaid = true;

        users[loan.borrower].accumulatedInterest += interest;

        payable(loan.lender).transfer(totalAmount);
        IERC721(loan.nftContract).transferFrom(
            address(this),
            loan.borrower,
            loan.tokenId
        );

        emit LoanRepaid(loanId, loan.borrower, totalAmount);
    }

    /**
     * @notice Liquidates a loan.
     * @param loanId The ID of the loan.
     */
    function liquidateLoan(uint256 loanId) external override nonReentrant {
        Loan storage loan = loans[loanId];

        require(
            block.timestamp >= loan.startTime + loan.duration,
            "Loan has not expired yet"
        );
        require(!loan.repaid, "Loan has already been repaid");
        require(loan.active, "Loan is not active");

        loan.active = false;

        payable(loan.lender).transfer(loan.loanAmount);

        emit LoanLiquidated(loanId, msg.sender);
    }

    /**
     * @notice Calculates the interest for a loan.
     * @param loanId The ID of the loan.
     * @return The interest amount.
     */
    function calculateInterest(
        uint256 loanId
    ) public view override returns (uint256) {
        Loan storage loan = loans[loanId];
        if (!loan.active || loan.borrower == address(0)) {
            return 0;
        }

        uint256 timeElapsed = block.timestamp - loan.startTime;
        return
            (loan.loanAmount * loan.interestRate * timeElapsed) /
            (100 * 365 days);
    }
}
