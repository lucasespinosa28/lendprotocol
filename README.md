# Lendscape Protocol

## Overview

Lendscape is a decentralized peer-to-peer (P2P) lending platform built on an EVM-compatible blockchain. It enables users to take out loans using their Intellectual Property NFTs (IP NFTs) as collateral. The protocol is designed to integrate seamlessly with Story Protocol, leveraging its `IIPAssetRegistry` to verify IP assets and its `IRoyaltyModule` to incorporate an IP's royalty-generating potential into the loan lifecycle.

This system creates a flexible and powerful financial tool for creators, allowing them to unlock the liquidity of their on-chain intellectual property.

## Core Concepts

The Lendscape protocol facilitates a trustless loan agreement between two parties: a **Borrower** and a **Lender**.

* **Borrower (IP Holder):** An individual who owns an NFT registered as an IP Asset on Story Protocol. They can lock this IP NFT into the Lendscape contract as collateral to request an ERC20 token loan.
* **Lender:** An individual who provides the ERC20 tokens to fund the borrower's loan request, earning interest upon successful repayment.

The entire process is managed by the `Lendscape.sol` smart contract, which acts as a decentralized escrow agent, holding the NFT collateral and ensuring all parties adhere to the agreed-upon terms.

## Key Features

* **NFT-Collateralized Loans:** Use any Story Protocol-registered IP NFT as collateral.
* **Peer-to-Peer Lending:** Lenders can directly fund loan requests they find attractive.
* **ERC20 Token Support:** Loans are denominated and paid in any standard ERC20 token, offering flexibility beyond native currencies.
* **Fixed-Term, Fixed-Repayment:** Loan terms (amount, repayment amount, duration) are set upfront, providing clarity for both parties.
* **Royalty-Aware Mechanics:** Integrates with Story Protocol's royalty system to allow borrowers to use their IP's generated revenue towards loan repayment or to avoid liquidation.
* **On-Chain Liquidation:** A transparent and automated process for lenders to claim collateral if a borrower defaults.
* **Secure and Non-Custodial:** The smart contract holds the collateral, and funds are transferred directly between the lender and borrower, minimizing counterparty risk.

## Story Protocol Integration

Lendscape's true power comes from its integration with Story Protocol's core components:

1.  **`IIPAssetRegistry`:** Before any loan request can be created, Lendscape verifies with the `IIPAssetRegistry` that the collateral NFT is a valid, registered IP Asset. This ensures that only legitimate on-chain IP can be used for loans.

2.  **`IRoyaltyModule` & `IIpRoyaltyVault`:** This is the most innovative aspect of the protocol. Lendscape queries the IP's associated `IpRoyaltyVault` to check for any claimable royalty revenue. This revenue can be used by the borrower during two critical phases:
    * **Repayment:** A borrower can use their accumulated royalties to cover part or all of their loan repayment, reducing the out-of-pocket expense.
    * **Liquidation:** If a loan expires, the contract first checks if the claimable royalties are sufficient to cover the full repayment amount. If so, the lender is paid with the royalties, and the borrower gets their NFT back, preventing an unnecessary liquidation.

## The Loan Lifecycle

A loan on the Lendscape protocol moves through several distinct stages:

### 1. Loan Request (`createLoanRequest`)

* **Action:** A **Borrower** initiates the process by calling this function.
* **Parameters:**
    * `nftContract`, `tokenId`: The IP NFT to be used as collateral.
    * `loanToken`: The ERC20 token the borrower wishes to receive.
    * `loanAmount`: The amount of `loanToken` the borrower wants.
    * `repaymentAmount`: The total amount (principal + interest) to be repaid.
    * `duration`: The loan's duration in seconds.
* **Process:**
    * The contract verifies the NFT is a registered IP Asset.
    * The borrower transfers the NFT into the Lendscape contract, where it is held in escrow.
    * A `LoanRequested` event is emitted, making the loan available for funding.

### 2. Funding the Loan (`fundLoan`)

* **Action:** A **Lender** finds an open loan request and decides to fund it.
* **Process:**
    * The lender must first `approve` the Lendscape contract to spend the `loanAmount` of the specified ERC20 token.
    * The lender calls `fundLoan`.
    * The contract transfers the `loanAmount` from the lender to the borrower.
    * The loan's `startTime` is recorded, and its status becomes `funded`.
    * A `LoanFunded` event is emitted.

### 3. Repaying the Loan (`repayLoan`)

* **Action:** The **Borrower** repays the loan before the `duration` expires.
* **Process:**
    * The borrower must first `approve` the Lendscape contract to spend the required ERC20 tokens.
    * The contract checks for any claimable royalties from the IP's vault.
    * The required `repaymentAmount` is covered first by any available royalties, and then by funds from the borrower's wallet.
    * The full `repaymentAmount` is transferred to the **Lender**.
    * Any excess funds (from royalties + wallet payment) are returned to the borrower.
    * The NFT collateral is transferred back to the **Borrower**.
    * A `LoanRepaid` event is emitted.

### 4. Loan Liquidation (`liquidateLoan`)

* **Action:** Anyone can call this function after the `startTime` + `duration` has passed and the loan has not been repaid.
* **Process:**
    * **Royalty Check:** The contract first checks the `IpRoyaltyVault` for claimable royalties.
        * **If Royalties >= Repayment Amount:** The loan is automatically repaid. The lender receives the full `repaymentAmount` from the royalties, and the NFT is returned to the **Borrower**. A `LoanRepaid` event is emitted.
        * **If Royalties < Repayment Amount:** The loan is liquidated. Any available royalties are transferred to the **Lender**. The NFT collateral is then also transferred to the **Lender**. A `LoanLiquidated` event is emitted.

## Contract Functions

* `createLoanRequest(address nftContract, uint256 tokenId, address loanToken, uint256 loanAmount, uint256 repaymentAmount, uint256 duration)`: Creates a new loan listing.
* `fundLoan(uint256 loanId)`: Allows a lender to fund an existing loan request.
* `repayLoan(uint256 loanId)`: Allows the borrower to repay the loan and reclaim their NFT.
* `liquidateLoan(uint256 loanId)`: Allows anyone to liquidate an expired loan.

## Events

* `LoanRequested`: Emitted when a new loan is created.
* `LoanFunded`: Emitted when a loan is funded by a lender.
* `LoanRepaid`: Emitted when a loan is successfully repaid.
* `LoanLiquidated`: Emitted when an expired loan's collateral is claimed by the lender.

## Setup & Deployment

To deploy the `Lendscape` contract, you must provide the addresses of Story Protocol's `RoyaltyModule` and `IPAssetRegistry` contracts in the constructor.

```solidity
constructor(address _royaltyModuleAddress, address _ipAssetRegistryAddress)
