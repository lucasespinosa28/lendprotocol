// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;
/**
 * @title LendscapeStorage
 * @author Your Name
 * @notice This contract defines the storage layout for the Lendscape peer-to-peer lending project.
 */

contract LendscapeStorage {
    // A struct to store information about each loan.
    struct Loan {
        uint256 id;
        address ipId; // The Story Protocol IP ID
        address borrower; // The owner of the NFT who wants the loan
        address lender; // The user who provides the ETH for the loan
        address nftContract;
        uint256 tokenId;
        address loanToken; // The ERC20 token for the loan
        uint256 loanAmount; // The amount of the ERC20 lent to the borrower
        uint256 repaymentAmount; // The total amount the borrower must repay
        uint256 duration;
        uint256 startTime;
        bool funded; // True if a lender has funded the loan
        bool repaid; // True if the loan is repaid or liquidated
    }

    // A mapping from loan IDs to Loan structs.
    mapping(uint256 => Loan) public loans;

    // The total number of loans created.
    uint256 public loanCounter;

    // The address of the contract owner.
    address public owner;
}
