// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "./Base.t.sol";
import {ILendscape} from "../src/interface/ILendscape.sol";

contract FundLoanTest is LendscapeTestBase {
    uint256 loanId = 1;

    function setUp() public override {
        super.setUp();
        vm.startPrank(borrower);
        nft.approve(address(lendscape), collateralTokenId);
        lendscape.createLoanRequest(address(nft), collateralTokenId, address(loanToken), LOAN_AMOUNT, REPAYMENT_AMOUNT, DURATION);
        vm.stopPrank();
    }

    function test_fundLoan_succeeds() public {
        uint256 lenderInitialBalance = loanToken.balanceOf(lender);
        uint256 borrowerInitialBalance = loanToken.balanceOf(borrower);

        vm.startPrank(lender);
        loanToken.approve(address(lendscape), LOAN_AMOUNT);
        
        vm.expectEmit(true, true, true, true);
        emit ILendscape.LoanFunded(loanId, ipId, borrower, lender, LOAN_AMOUNT);

        lendscape.fundLoan(loanId);
        vm.stopPrank();

        Lendscape.Loan memory loan = lendscape.loans(loanId);
        assertTrue(loan.funded);
        assertEq(loan.lender, lender);
        assertEq(loanToken.balanceOf(lender), lenderInitialBalance - LOAN_AMOUNT);
        assertEq(loanToken.balanceOf(borrower), borrowerInitialBalance + LOAN_AMOUNT);
    }

    function test_revert_if_already_funded() public {
        vm.startPrank(lender);
        loanToken.approve(address(lendscape), LOAN_AMOUNT);
        lendscape.fundLoan(loanId);
        vm.stopPrank();

        vm.startPrank(otherUser);
        loanToken.mint(otherUser, LOAN_AMOUNT);
        loanToken.approve(address(lendscape), LOAN_AMOUNT);

        vm.expectRevert("Loan has already been funded");
        lendscape.fundLoan(loanId);
        vm.stopPrank();
    }
}
