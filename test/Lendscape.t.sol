// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {Lendscape} from "../src/core/Lendscape.sol";
import {MockNFT} from "./mock/MockNFT.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 * @title LendscapeTest
 * @author Your Name
 * @notice Test suite for the P2P Lendscape contract.
 * Bob is the Borrower (has NFT, needs ETH).
 * Alice is the Lender (has ETH, wants yield).
 */
contract LendscapeTest is Test {
    // Contracts
    Lendscape public lendscape;
    MockNFT public mockNft;

    // Users
    address public bob_borrower = address(1);
    address public alice_lender = address(2);

    // Loan parameters
    uint256 public loanAmount = 1 ether;
    uint256 public repaymentAmount = 1.1 ether; // 10% interest
    uint256 public duration = 30 days;
    uint256 public nftTokenId;

    /**
     * @notice Sets up the test environment before each test case.
     */
    function setUp() public {
        // Deploy contracts
        lendscape = new Lendscape();
        mockNft = new MockNFT();

        // Mint an NFT for Bob (Borrower)
        vm.startPrank(bob_borrower);
        nftTokenId = mockNft.mint(bob_borrower);
        vm.stopPrank();

        // Give Alice (Lender) some ETH to fund the loan
        vm.deal(alice_lender, 5 ether);
    }

    /**
     * @notice Full successful loan cycle: request -> fund -> repay.
     */
    function test_full_loan_cycle_success() public {
        // 1. Bob creates a loan request
        vm.startPrank(bob_borrower);
        mockNft.approve(address(lendscape), nftTokenId);
        lendscape.createLoanRequest(
            address(mockNft),
            nftTokenId,
            loanAmount,
            repaymentAmount,
            duration
        );
        // Verify NFT is now held by the contract
        assertEq(mockNft.ownerOf(nftTokenId), address(lendscape));
        vm.stopPrank();

        // 2. Alice funds the loan
        uint256 bob_initial_balance = bob_borrower.balance;
        vm.startPrank(alice_lender);
        lendscape.fundLoan{value: loanAmount}(1);
        // Verify Bob received the loan amount
        assertEq(
            bob_borrower.balance,
            bob_initial_balance + loanAmount,
            "Bob should receive the loan amount"
        );
        vm.stopPrank();

        // 3. Bob repays the loan
        vm.warp(block.timestamp + 15 days); // Fast-forward time
        uint256 alice_initial_balance = alice_lender.balance;
        vm.startPrank(bob_borrower);
        lendscape.repayLoan{value: repaymentAmount}(1);

        // Verify Bob gets his NFT back
        assertEq(
            mockNft.ownerOf(nftTokenId),
            bob_borrower,
            "Bob should get his NFT back"
        );
        // Verify Alice receives her repayment
        assertEq(
            alice_lender.balance,
            alice_initial_balance + repaymentAmount,
            "Alice should receive the repayment"
        );
        vm.stopPrank();
    }

    /**
     * @notice Tests liquidation: request -> fund -> expire -> liquidate.
     */
    function test_liquidateLoan() public {
        // 1. Bob creates a loan request
        vm.startPrank(bob_borrower);
        mockNft.approve(address(lendscape), nftTokenId);
        lendscape.createLoanRequest(
            address(mockNft),
            nftTokenId,
            loanAmount,
            repaymentAmount,
            duration
        );
        vm.stopPrank();

        // 2. Alice funds the loan
        vm.startPrank(alice_lender);
        lendscape.fundLoan{value: loanAmount}(1);
        vm.stopPrank();

        // 3. Time expires
        vm.warp(block.timestamp + duration + 1 days);

        // 4. Alice liquidates the loan
        vm.startPrank(alice_lender);
        lendscape.liquidateLoan(1);

        // Verify Alice now owns the NFT
        assertEq(
            mockNft.ownerOf(nftTokenId),
            alice_lender,
            "Alice should receive the NFT upon liquidation"
        );
        vm.stopPrank();
    }
}
