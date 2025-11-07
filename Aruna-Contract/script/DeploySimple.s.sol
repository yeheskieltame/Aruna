// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/SimpleAruna.sol";

contract DeploySimple is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        // Deploy SimpleAruna
        // For Base Sepolia testnet
        address usdc = 0xd9aaeC86b65d86f6A7B5B1B0C42FfA531770b16F;
        address owner = msg.sender;

        SimpleAruna simpleAruna = new SimpleAruna(usdc, owner);

        vm.stopBroadcast();

        console.log("=== SimpleAruna Deployment ===");
        console.log("SimpleAruna:", address(simpleAruna));
        console.log("USDC:", usdc);
        console.log("Owner:", owner);
        console.log("");

        console.log("=== Next Steps ===");
        console.log("1. Fund contract with USDC for grants");
        console.log("2. Test commitInvoice function");
        console.log("3. Test depositCollateral function");
        console.log("4. Test settleInvoice function");
    }
}