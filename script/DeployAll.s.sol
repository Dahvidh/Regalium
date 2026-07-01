// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
//import { AccessControl } from "src/AccessControl.sol";
import { RegaliumToken } from "src/Regalium.sol";
import { Buyback } from "src/RegaliumBuyback.sol";
import { GameStore } from "src/RegaliumGameStore.sol";
import { Presale } from "src/RegaliumPresale.sol";
import { Staking } from "src/RegaliumStaking.sol";
import "forge-std/console.sol";

contract DeployAll is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

         address maticUsdFeed = address(0x565Ffe93b3b9EF5Ffc0e0e3ee2b6B7f43f31ff29);


        // Deploy contracts
       // AccessControl access = new AccessControl();
        RegaliumToken regalium = new RegaliumToken(maticUsdFeed);
        Buyback buyback = new Buyback(address(regalium));
        GameStore store = new GameStore(address(regalium));
      Presale presale = new Presale(address(regalium));
       Staking staking = new Staking(address(regalium));

        vm.stopBroadcast();

        console.log("Deployment complete!");
        //console.log("AccessControl:", address(access));
        console.log("Regalium:", address(regalium));
        console.log("Buyback:", address(buyback));
        console.log("GameStore:", address(store));
        console.log("Presale:", address(presale));
        console.log("Staking:", address(staking));
    }
}
