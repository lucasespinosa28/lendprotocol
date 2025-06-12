// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;
/**
 * @title ILendscape
 * @author Your Name
 * @notice This interface defines the functions and events for the peer-to-peer Lendscape platform.
 */

interface ILendscape {
    event LoanRequested(
        uint256 indexed loanId,
        address indexed ipId,
        address indexed borrower,
        address nftContract,
        uint256 tokenId,
        address loanToken,
        uint256 loanAmount,
        uint256 repaymentAmount,
        uint256 duration
    );

    event LoanFunded(
        uint256 indexed loanId, address indexed ipId, address indexed lender, address borrower, uint256 amountFunded
    );

    event LoanRepaid(uint256 indexed loanId, address indexed ipId, address indexed borrower, uint256 amountPaid);

    event LoanLiquidated(uint256 indexed loanId, address indexed ipId, address indexed lender);

    function createLoanRequest(
        address nftContract,
        uint256 tokenId,
        address loanToken,
        uint256 loanAmount,
        uint256 repaymentAmount,
        uint256 duration
    ) external;

    function fundLoan(uint256 loanId) external;

    function repayLoan(uint256 loanId) external;

    function liquidateLoan(uint256 loanId) external;
}
