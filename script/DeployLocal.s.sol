// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {Lendscape} from "../src/core/Lendscape.sol";
import {MockIIPAssetRegistry} from "../test/mock/MockIIPAssetRegistry.sol";
import {MockRoyaltyModule} from "../test/mock/MockRoyaltyModule.sol";

contract DeployLocal is Script {
    function run() external returns (Lendscape) {
        vm.startBroadcast();

        // On a local network, we need to deploy our own mock versions
        // of the Story Protocol contracts.
        console.log("Deploying MockIIPAssetRegistry...");
        MockIIPAssetRegistry mockRegistry = new MockIIPAssetRegistry();
        console.log("Deployed MockIIPAssetRegistry to:", address(mockRegistry));

        console.log("Deploying MockRoyaltyModule...");
        MockRoyaltyModule mockRoyaltyModule = new MockRoyaltyModule();
        console.log("Deployed MockRoyaltyModule to:", address(mockRoyaltyModule));

        // Now, deploy the Lendscape contract with the addresses of our mocks.
        console.log("Deploying Lendscape...");
        Lendscape lendscape = new Lendscape(address(mockRoyaltyModule), address(mockRegistry));
        console.log("Deployed Lendscape to:", address(lendscape));

        vm.stopBroadcast();
        return lendscape;
    }
}
