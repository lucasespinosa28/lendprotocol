// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "./Base.t.sol";
import {ILendscape} from "../src/interface/ILendscape.sol";

contract RepayLoanTest is LendscapeTestBase {
    uint256 loanId = 1;

    function setUp() public override {
        super.setUp();
        // Create and fund the loan
        vm.startPrank(borrower);
        nft.approve(address(lendscape), collateralTokenId);
        lendscape.createLoanRequest(address(nft), collateralTokenId, address(loanToken), LOAN_AMOUNT, REPAYMENT_AMOUNT, DURATION);
        vm.stopPrank();

        vm.startPrank(lender);
        loanToken.approve(address(lendscape), LOAN_AMOUNT);
        lendscape.fundLoan(loanId);
        vm.stopPrank();
    }

    function test_repayLoan_succeeds_with_no_royalties() public {
        loanToken.mint(borrower, REPAYMENT_AMOUNT);
        uint256 lenderInitialBalance = loanToken.balanceOf(lender);

        vm.startPrank(borrower);
        loanToken.approve(address(lendscape), REPAYMENT_AMOUNT);

        vm.expectEmit(true, true, true, true);
        emit ILendscape.LoanRepaid(loanId, ipId, borrower, REPAYMENT_AMOUNT);

        lendscape.repayLoan(loanId);
        vm.stopPrank();

        assertEq(nft.ownerOf(collateralTokenId), borrower);
        assertEq(loanToken.balanceOf(lender), lenderInitialBalance + REPAYMENT_AMOUNT);
        Lendscape.Loan memory loan = lendscape.loans(loanId);
        assertTrue(loan.repaid);
    }

    function test_revert_if_not_borrower() public {
        vm.startPrank(otherUser);
        vm.expectRevert("You are not the borrower");
        lendscape.repayLoan(loanId);
        vm.stopPrank();
    }
}
