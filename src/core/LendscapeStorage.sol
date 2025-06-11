// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/**
 * @title LendscapeStorage
 * @author Your Name
 * @notice This contract defines the storage layout for the Lendscape project.
 */
contract LendscapeStorage {
    // A struct to store information about each loan.
    struct Loan {
        uint256 id;
        address lender;
        address borrower;
        address nftContract;
        uint256 tokenId;
        uint256 loanAmount;
        uint256 interestRate;
        uint256 duration;
        uint256 startTime;
        bool active;
        bool repaid;
    }

    // A struct to store information about each user.
    struct User {
        uint256[] lentNFTs;
        uint256[] borrowedNFTs;
        uint256 accumulatedInterest;
    }

    // A mapping from loan IDs to Loan structs.
    mapping(uint256 => Loan) public loans;

    // A mapping from user addresses to User structs.
    mapping(address => User) public users;

    // The total number of loans created.
    uint256 public loanCounter;

    // The address of the contract owner.
    address public owner;
}

