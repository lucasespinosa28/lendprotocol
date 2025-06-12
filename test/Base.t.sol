// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {Lendscape} from "../src/core/Lendscape.sol";

// Import existing and new mocks from the mock directory
import {MockERC20} from "./mock/MockERC20.sol";
import {MockNFT} from "./mock/MockNFT.sol";
import {MockIIPAssetRegistry} from "./mock/MockIIPAssetRegistry.sol";
import {MockRoyaltyModule} from "./mock/MockRoyaltyModule.sol";
import {MockIpRoyaltyVault} from "./mock/MockIpRoyaltyVault.sol";
import {MockIIPAccount} from "./mock/MockIIPAccount.sol";

// --- Base Test Contract ---
contract LendscapeTestBase is Test {
    Lendscape public lendscape;
    MockNFT public nft;
    MockERC20 public loanToken;
    MockIIPAssetRegistry public registry;
    MockRoyaltyModule public royaltyModule;
    MockIpRoyaltyVault public royaltyVault;
    MockIIPAccount public ipAccount;

    address public owner = makeAddr("owner");
    address public borrower = makeAddr("borrower");
    address public lender = makeAddr("lender");
    address public otherUser = makeAddr("otherUser");

    uint256 public collateralTokenId = 0;
    address public ipId;

    uint256 public constant LOAN_AMOUNT = 100 ether;
    uint256 public constant REPAYMENT_AMOUNT = 110 ether; // 10% interest
    uint256 public constant DURATION = 30 days;

    function setUp() public virtual {
        vm.startPrank(owner);
        // Deploy all contracts
        nft = new MockNFT();
        loanToken = new MockERC20("Mock Token", "MTKN");
        registry = new MockIIPAssetRegistry();
        royaltyModule = new MockRoyaltyModule();
        royaltyVault = new MockIpRoyaltyVault();
        ipAccount = new MockIIPAccount();
        lendscape = new Lendscape(address(royaltyModule), address(registry));
        vm.stopPrank();

        // Setup initial state
        nft.mint(borrower);
        loanToken.mint(lender, 1_000_000 ether);

        // Configure Story Protocol Mocks
        ipId = address(ipAccount);
        
        registry.setIpId(block.chainid, address(nft), collateralTokenId, ipId);
        registry.setRegistered(ipId, true);
        royaltyModule.setIpRoyaltyVault(ipId, address(royaltyVault));
    }
}
