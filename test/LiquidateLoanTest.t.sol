// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "./Base.t.sol";
import {ILendscape} from "../src/interface/ILendscape.sol";

contract LiquidateLoanTest is LendscapeTestBase {
    uint256 loanId = 1;

    function setUp() public override {
        super.setUp();
        // Create and fund the loan
        vm.startPrank(borrower);
        nft.approve(address(lendscape), collateralTokenId);
        lendscape.createLoanRequest(
            address(nft), collateralTokenId, address(loanToken), LOAN_AMOUNT, REPAYMENT_AMOUNT, DURATION
        );
        vm.stopPrank();

        vm.startPrank(lender);
        loanToken.approve(address(lendscape), LOAN_AMOUNT);
        lendscape.fundLoan(loanId);
        vm.stopPrank();
    }

    function test_liquidateLoan_succeeds_transfers_nft_to_lender() public {
        // Fast forward time
        vm.warp(block.timestamp + DURATION + 1 days);

        vm.startPrank(otherUser); // Anyone can liquidate

        vm.expectEmit(true, true, true, true);
        emit ILendscape.LoanLiquidated(loanId, ipId, lender);

        lendscape.liquidateLoan(loanId);
        vm.stopPrank();

        assertEq(nft.ownerOf(collateralTokenId), lender);
        ( /* uint256 id */
            ,
            /* address ipId */
            ,
            /* address borrower */
            ,
            /* address lender */
            ,
            /* address nftContract */
            ,
            /* uint256 tokenId */
            ,
            /* address loanToken */
            ,
            /* uint256 loanAmount */
            ,
            /* uint256 repaymentAmount */
            ,
            /* uint256 duration */
            ,
            /* uint256 startTime */
            ,
            /* bool funded */
            ,
            bool repaid_
        ) = lendscape.loans(loanId);
        assertTrue(repaid_);
    }

    function test_liquidateLoan_succeeds_repays_with_royalties() public {
        // Setup royalties to be greater than repayment
        uint256 royaltyAmount = REPAYMENT_AMOUNT + 1 ether;
        royaltyVault.setClaimableRevenue(ipId, address(loanToken), royaltyAmount);

        // Simulate the royalty vault holding the funds
        loanToken.mint(address(royaltyVault), royaltyAmount);

        // This part is tricky in a mock. We simulate the transfer from the IP Account
        // which would be called by the royalty claim.
        vm.prank(address(ipAccount));
        loanToken.approve(address(lendscape), royaltyAmount);

        // Fast forward time
        vm.warp(block.timestamp + DURATION + 1 days);

        uint256 lenderInitialBalance = loanToken.balanceOf(lender);
        uint256 borrowerInitialBalance = loanToken.balanceOf(borrower);

        vm.startPrank(otherUser);

        vm.expectEmit(true, true, true, true);
        emit ILendscape.LoanRepaid(loanId, ipId, borrower, REPAYMENT_AMOUNT);

        lendscape.liquidateLoan(loanId);
        vm.stopPrank();

        assertEq(nft.ownerOf(collateralTokenId), borrower); // NFT returns to borrower
        assertEq(loanToken.balanceOf(lender), lenderInitialBalance + REPAYMENT_AMOUNT);
        assertEq(loanToken.balanceOf(borrower), borrowerInitialBalance + (royaltyAmount - REPAYMENT_AMOUNT)); // Gets excess
    }

    function test_revert_if_loan_not_expired() public {
        vm.startPrank(otherUser);
        vm.expectRevert("Loan has not expired yet");
        lendscape.liquidateLoan(loanId);
        vm.stopPrank();
    }
}
