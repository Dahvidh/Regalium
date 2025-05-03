// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Script.sol";
import "../src/Regalium.sol";

contract DeployRegaliumToken is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        // ✅ CHECKSUMMED ADDRESS
        address maticUsdFeed = 0xd9FFdb71EbE7496cC440152d43986Aae0AB76665;

        vm.startBroadcast(deployerPrivateKey);
        RegaliumToken token = new RegaliumToken(maticUsdFeed);
        vm.stopBroadcast();

        console.log("RegaliumToken deployed at:", address(token));
    }
}
