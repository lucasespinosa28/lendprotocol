// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ILendscape
 * @author Your Name
 * @notice This interface defines the functions and events for the peer-to-peer Lendscape platform.
 */
interface ILendscape {
    /**
     * @notice Emitted when a borrower creates a new loan request.
     * @param loanId The ID of the loan request.
     * @param borrower The address of the borrower (NFT owner).
     * @param nftContract The address of the NFT contract.
     * @param tokenId The ID of the NFT.
     * @param loanAmount The amount of ETH requested.
     * @param repaymentAmount The amount of ETH to be repaid.
     * @param duration The duration of the loan.
     */
    event LoanRequested(
        uint256 indexed loanId,
        address indexed borrower,
        address indexed nftContract,
        uint256 tokenId,
        uint256 loanAmount,
        uint256 repaymentAmount,
        uint256 duration
    );

    /**
     * @notice Emitted when a lender funds a loan request.
     * @param loanId The ID of the loan.
     * @param borrower The address of the borrower.
     * @param lender The address of the lender.
     * @param amountFunded The amount of ETH funded.
     */
    event LoanFunded(
        uint256 indexed loanId,
        address indexed borrower,
        address indexed lender,
        uint256 amountFunded
    );

    /**
     * @notice Emitted when a borrower repays a loan.
     * @param loanId The ID of the loan.
     * @param borrower The address of the borrower.
     * @param amountPaid The total amount paid to repay the loan.
     */
    event LoanRepaid(
        uint256 indexed loanId,
        address indexed borrower,
        uint256 amountPaid
    );

    /**
     * @notice Emitted when a loan is liquidated by the lender.
     * @param loanId The ID of the loan.
     * @param lender The address of the lender who now owns the NFT.
     */
    event LoanLiquidated(uint256 indexed loanId, address indexed lender);

    function createLoanRequest(
        address nftContract,
        uint256 tokenId,
        uint256 loanAmount,
        uint256 repaymentAmount,
        uint256 duration
    ) external;

    function fundLoan(uint256 loanId) external payable;

    function repayLoan(uint256 loanId) external payable;

    function liquidateLoan(uint256 loanId) external;
}
