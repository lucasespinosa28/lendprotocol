// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {Lendscape} from "../src/core/Lendscape.sol";
import {MockNFT} from "./mock/MockNFT.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {ILendscape} from "../src/interface/ILendscape.sol"; // keep this import if you want to use types, but not required

/**
 * @title LendscapeTest
 * @author Your Name
 * @notice Test suite for the Lendscape contract.
 */
contract LendscapeTest is Test {
    // Contracts
    Lendscape public lendscape;
    MockNFT public mockNft;

    // Users
    address public lender = address(1);
    address public borrower = address(2);

    // Loan parameters
    uint256 public loanAmount = 1 ether;
    uint256 public interestRate = 10; // 10% APR
    uint256 public duration = 30 days;
    uint256 public nftTokenId;

    /**
     * @notice Sets up the test environment before each test case.
     */
    function setUp() public {
        // Deploy contracts
        lendscape = new Lendscape();
        mockNft = new MockNFT();

        // Mint an NFT for the lender
        vm.startPrank(lender);
        nftTokenId = mockNft.mint(lender);
        vm.stopPrank();

        // Give some ETH to the borrower for collateral
        vm.deal(borrower, 5 ether);
    }

    //--- Test listNFT ---

    /**
     * @notice Tests if an NFT can be successfully listed for a loan.
     */
    function test_listNFT() public {
        vm.startPrank(lender);
        mockNft.approve(address(lendscape), nftTokenId);

        // Expect the NFTListed event to be emitted
        vm.expectEmit(true, true, true, true);
        emit ILendscape.NFTListed(
            1,
            lender,
            address(mockNft),
            nftTokenId,
            loanAmount,
            interestRate,
            duration
        );

        lendscape.listNFT(
            address(mockNft),
            nftTokenId,
            loanAmount,
            interestRate,
            duration
        );

        // Verify NFT is now owned by the contract
        assertEq(
            mockNft.ownerOf(nftTokenId),
            address(lendscape),
            "Contract should own the NFT"
        );

        // Verify loan details
        (
            ,
            address loanLender,
            ,
            ,
            ,
            uint256 amount,
            ,
            ,
            ,
            bool active,

        ) = lendscape.loans(1);
        assertEq(loanLender, lender, "Lender address is incorrect");
        assertEq(amount, loanAmount, "Loan amount is incorrect");
        assertTrue(active, "Loan should be active");
        vm.stopPrank();
    }

    //--- Test borrowNFT ---

    /**
     * @notice Tests if a listed NFT can be borrowed successfully.
     */
    function test_borrowNFT() public {
        // 1. Lender lists the NFT
        vm.startPrank(lender);
        mockNft.approve(address(lendscape), nftTokenId);
        lendscape.listNFT(
            address(mockNft),
            nftTokenId,
            loanAmount,
            interestRate,
            duration
        );
        vm.stopPrank();

        // 2. Borrower borrows the NFT
        vm.startPrank(borrower);
        // Expect LoanCreated event
        vm.expectEmit(true, true, true, false);
        emit ILendscape.LoanCreated(
            1,
            lender,
            borrower,
            address(mockNft),
            nftTokenId,
            loanAmount,
            interestRate,
            duration
        );

        lendscape.borrowNFT{value: loanAmount}(1);

        // Verify loan details
        (
            ,
            ,
            address loanBorrower,
            ,
            ,
            ,
            ,
            ,
            uint256 startTime,
            ,

        ) = lendscape.loans(1);
        assertEq(loanBorrower, borrower, "Borrower address is incorrect");
        assertGt(startTime, 0, "Start time should be set");
        vm.stopPrank();
    }

    /**
     * @notice Tests that borrowing fails if insufficient collateral is provided.
     */
    function test_fail_borrowNFT_insufficientCollateral() public {
        // 1. Lender lists the NFT
        vm.startPrank(lender);
        mockNft.approve(address(lendscape), nftTokenId);
        lendscape.listNFT(
            address(mockNft),
            nftTokenId,
            loanAmount,
            interestRate,
            duration
        );
        vm.stopPrank();

        // 2. Borrower attempts to borrow with not enough value
        vm.startPrank(borrower);
        vm.expectRevert("Not enough collateral");
        lendscape.borrowNFT{value: loanAmount - 1 wei}(1);
        vm.stopPrank();
    }

    //--- Test repayLoan ---

    /**
     * @notice Tests if a loan can be repaid successfully.
     */
    function test_repayLoan() public {
        // 1. List and borrow
        test_borrowNFT();

        // 2. Fast forward time
        uint256 interest = lendscape.calculateInterest(1);
        uint256 repayAmount = loanAmount + interest;

        // 3. Repay the loan
        vm.startPrank(borrower);
        uint256 lenderInitialBalance = lender.balance;

        // Expect LoanRepaid event
        vm.expectEmit(true, true, false, false);
        emit ILendscape.LoanRepaid(1, borrower, repayAmount);

        lendscape.repayLoan{value: repayAmount}(1);

        // Verify NFT is returned to the borrower
        assertEq(
            mockNft.ownerOf(nftTokenId),
            borrower,
            "Borrower should own the NFT after repayment"
        );

        // Verify lender received the payment
        assertEq(
            lender.balance,
            lenderInitialBalance + repayAmount,
            "Lender did not receive correct payment"
        );

        // Verify loan is no longer active
        (
            ,
            ,
            ,
            ,
            ,
            ,
            ,
            ,
            ,
            bool active,
            bool repaid
        ) = lendscape.loans(1);
        assertFalse(active, "Loan should be inactive");
        assertTrue(repaid, "Loan should be marked as repaid");
        vm.stopPrank();
    }

    //--- Test liquidateLoan ---

    /**
     * @notice Tests if a loan can be liquidated after expiration.
     */
    function test_liquidateLoan() public {
        // 1. List and borrow
        test_borrowNFT();

        // 2. Fast forward time past the loan duration
        vm.warp(block.timestamp + duration + 1 days);

        // 3. Anyone can liquidate, but let's have the lender do it
        vm.startPrank(lender);
        uint256 lenderInitialBalance = lender.balance;

        // Expect LoanLiquidated event
        vm.expectEmit(true, true, false, false);
        emit ILendscape.LoanLiquidated(1, lender);

        lendscape.liquidateLoan(1);

        // The NFT is transferred to the lender in a real scenario.
        // In this implementation, the collateral is sent to the lender.
        // A more complex implementation might give the NFT to the lender.
        assertEq(
            lender.balance,
            lenderInitialBalance + loanAmount,
            "Lender did not receive collateral"
        );

        (
            ,
            ,
            ,
            ,
            ,
            ,
            ,
            ,
            ,
            bool active,
            bool repaid
        ) = lendscape.loans(1);
        assertFalse(active, "Loan should be inactive after liquidation");
        assertFalse(repaid, "Loan should not be marked as repaid");
        vm.stopPrank();
    }

    /**
     * @notice Tests that liquidation fails if the loan has not expired.
     */
    function test_fail_liquidateLoan_tooEarly() public {
        // 1. List and borrow
        test_borrowNFT();

        // 2. Try to liquidate before duration is over
        vm.startPrank(lender);
        vm.expectRevert("Loan has not expired yet");
        lendscape.liquidateLoan(1);
        vm.stopPrank();
    }
}
