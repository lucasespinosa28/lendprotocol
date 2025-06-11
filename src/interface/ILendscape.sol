// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 * @title ILendscape
 * @author Your Name
 * @notice This interface defines the functions and events for the Lendscape NFT lending and borrowing platform.
 */
interface ILendscape {
    /**
     * @notice Emitted when an NFT is listed for a loan.
     * @param loanId The ID of the loan listing.
     * @param lender The address of the lender.
     * @param nftContract The address of the NFT contract.
     * @param tokenId The ID of the NFT.
     * @param loanAmount The potential loan amount.
     * @param interestRate The interest rate for the loan.
     * @param duration The duration of the loan.
     */
    event NFTListed(
        uint256 indexed loanId,
        address indexed lender,
        address indexed nftContract,
        uint256 tokenId,
        uint256 loanAmount,
        uint256 interestRate,
        uint256 duration
    );

    /**
     * @notice Emitted when a new loan is created (i.e., an NFT is borrowed).
     * @param loanId The ID of the loan.
     * @param lender The address of the lender.
     * @param borrower The address of the borrower.
     * @param nftContract The address of the NFT contract.
     * @param tokenId The ID of the NFT.
     * @param loanAmount The amount of the loan (collateral).
     * @param interestRate The interest rate of the loan.
     * @param duration The duration of the loan.
     */
    event LoanCreated(
        uint256 indexed loanId,
        address indexed lender,
        address indexed borrower,
        address nftContract,
        uint256 tokenId,
        uint256 loanAmount,
        uint256 interestRate,
        uint256 duration
    );

    /**
     * @notice Emitted when a loan is repaid.
     * @param loanId The ID of the loan.
     * @param borrower The address of the borrower.
     * @param amountPaid The total amount paid to repay the loan.
     */
    event LoanRepaid(uint256 indexed loanId, address indexed borrower, uint256 amountPaid);

    /**
     * @notice Emitted when a loan is liquidated.
     * @param loanId The ID of the loan.
     * @param liquidator The address that triggered the liquidation.
     */
    event LoanLiquidated(uint256 indexed loanId, address indexed liquidator);

    /**
     * @notice Lists an NFT for lending.
     * @param nftContract The address of the NFT contract.
     * @param tokenId The ID of the NFT.
     * @param loanAmount The amount of the loan.
     * @param interestRate The interest rate of the loan.
     * @param duration The duration of the loan.
     */
    function listNFT(address nftContract, uint256 tokenId, uint256 loanAmount, uint256 interestRate, uint256 duration)
        external;

    /**
     * @notice Borrows an NFT.
     * @param loanId The ID of the loan.
     */
    function borrowNFT(uint256 loanId) external payable;

    /**
     * @notice Repays a loan.
     * @param loanId The ID of the loan.
     */
    function repayLoan(uint256 loanId) external payable;

    /**
     * @notice Liquidates a loan.
     * @param loanId The ID of the loan.
     */
    function liquidateLoan(uint256 loanId) external;

    /**
     * @notice Calculates the interest for a loan.
     * @param loanId The ID of the loan.
     * @return The interest amount.
     */
    function calculateInterest(uint256 loanId) external view returns (uint256);
}
