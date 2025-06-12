// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "./Base.t.sol";
import {ILendscape} from "../src/interface/ILendscape.sol";

contract CreateLoanRequestTest is LendscapeTestBase {
    uint256 loanId = 1;

    function setUp() public override {
        super.setUp();
        vm.startPrank(borrower);
        nft.approve(address(lendscape), collateralTokenId);
        vm.stopPrank();
    }

    function test_createLoanRequest_succeeds() public {
        vm.startPrank(borrower);
        
        vm.expectEmit(true, true, true, true);
        emit ILendscape.LoanRequested(loanId, ipId, borrower, address(nft), collateralTokenId, address(loanToken), LOAN_AMOUNT, REPAYMENT_AMOUNT, DURATION);
        
        lendscape.createLoanRequest(address(nft), collateralTokenId, address(loanToken), LOAN_AMOUNT, REPAYMENT_AMOUNT, DURATION);

        Lendscape.Loan memory loan = lendscape.loans(loanId);
        assertEq(loan.borrower, borrower);
        assertEq(loan.nftContract, address(nft));
        assertEq(loan.tokenId, collateralTokenId);
        assertEq(nft.ownerOf(collateralTokenId), address(lendscape));
    }

    function test_revert_if_not_nft_owner() public {
        vm.startPrank(otherUser);
        nft.approve(address(lendscape), collateralTokenId);
        
        vm.expectRevert("You are not the owner of this NFT");
        lendscape.createLoanRequest(address(nft), collateralTokenId, address(loanToken), LOAN_AMOUNT, REPAYMENT_AMOUNT, DURATION);
    }

    function test_revert_if_loan_amount_is_zero() public {
        vm.startPrank(borrower);
        vm.expectRevert("Loan amount must be positive");
        lendscape.createLoanRequest(address(nft), collateralTokenId, address(loanToken), 0, REPAYMENT_AMOUNT, DURATION);
    }
}
