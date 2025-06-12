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
        emit ILendscape.LoanRequested(
            loanId,
            ipId,
            borrower,
            address(nft),
            collateralTokenId,
            address(loanToken),
            LOAN_AMOUNT,
            REPAYMENT_AMOUNT,
            DURATION
        );

        lendscape.createLoanRequest(
            address(nft), collateralTokenId, address(loanToken), LOAN_AMOUNT, REPAYMENT_AMOUNT, DURATION
        );

        ( /* uint256 id */
            ,
            /* address ipId */
            ,
            address borrower_,
            /* address lender */
            ,
            address nftContract_,
            uint256 tokenId_,
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
            /* bool repaid */
        ) = lendscape.loans(loanId);

        assertEq(borrower_, borrower);
        assertEq(nftContract_, address(nft));
        assertEq(tokenId_, collateralTokenId);
        assertEq(nft.ownerOf(collateralTokenId), address(lendscape));
    }

    function test_revert_if_not_nft_owner() public {
        vm.startPrank(otherUser);

        vm.expectRevert("You are not the owner of this NFT");
        lendscape.createLoanRequest(
            address(nft), collateralTokenId, address(loanToken), LOAN_AMOUNT, REPAYMENT_AMOUNT, DURATION
        );
        vm.stopPrank();
    }

    function test_revert_if_loan_amount_is_zero() public {
        vm.startPrank(borrower);
        vm.expectRevert("Loan amount must be positive");
        lendscape.createLoanRequest(address(nft), collateralTokenId, address(loanToken), 0, REPAYMENT_AMOUNT, DURATION);
    }
}
