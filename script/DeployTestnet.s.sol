// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {Lendscape} from "../src/core/Lendscape.sol";

contract DeployTestnet is Script {
    function run() external returns (Lendscape) {
        // Load the private key from the environment variable set in your .env file
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        // --- Sepolia Testnet Addresses for Story Protocol ---
        // Replace these with the actual addresses for the network you are using.
        address royaltyModuleAddress = 0xD2f60c40fEbccf6311f8B47c4f2Ec6b040400086;
        address ipAssetRegistryAddress = 0x77319B4031e6eF1250907aa00018B8B1c67a244b;

        require(royaltyModuleAddress != address(0), "Royalty Module address cannot be zero.");
        require(ipAssetRegistryAddress != address(0), "IP Asset Registry address cannot be zero.");

        vm.startBroadcast(deployerPrivateKey);

        console.log("Deploying Lendscape to testnet...");
        Lendscape lendscape = new Lendscape(royaltyModuleAddress, ipAssetRegistryAddress);
        console.log("Deployed Lendscape to:", address(lendscape));

        vm.stopBroadcast();
        return lendscape;
    }
}
