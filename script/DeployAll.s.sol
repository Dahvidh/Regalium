// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Script.sol";
import "forge-std/console.sol";

import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import {RegaliumToken} from "src/Regalium.sol";
import {GameStore} from "src/RegaliumGameStore.sol";
import {Presale} from "src/RegaliumPresale.sol";

contract DeployAll is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey);

        // Chainlink MATIC/USD feed
        address maticUsdFeed =
            0x565Ffe93b3b9EF5Ffc0e0e3ee2b6B7f43f31ff29;

        // ---------------------------------------------------------
        // 1. Deploy RegaliumToken
        // ---------------------------------------------------------

        RegaliumToken regalium = new RegaliumToken(maticUsdFeed);

        // ---------------------------------------------------------
        // 2. Deploy GameStore implementation
        // ---------------------------------------------------------

        GameStore gameStoreImplementation = new GameStore();

        // Encode initialize(token, owner)
        bytes memory gameStoreInitData = abi.encodeCall(
            GameStore.initialize,
            (address(regalium), deployer)
        );

        // Deploy GameStore proxy
        ERC1967Proxy gameStoreProxy = new ERC1967Proxy(
            address(gameStoreImplementation),
            gameStoreInitData
        );

        GameStore store = GameStore(address(gameStoreProxy));

        // ---------------------------------------------------------
        // 3. Deploy Presale implementation
        // ---------------------------------------------------------

        Presale presaleImplementation = new Presale();

        // Encode initialize(token, owner)
        bytes memory presaleInitData = abi.encodeCall(
            Presale.initialize,
            (address(regalium), deployer)
        );

        // Deploy Presale proxy
        ERC1967Proxy presaleProxy = new ERC1967Proxy(
            address(presaleImplementation),
            presaleInitData
        );

        Presale presale = Presale(address(presaleProxy));

        vm.stopBroadcast();

        // ---------------------------------------------------------
        // Deployment information
        // ---------------------------------------------------------

        console.log("========================================");
        console.log("Regalium Deployment Complete");
        console.log("========================================");

        console.log("Deployer:", deployer);

        console.log("Regalium Token:", address(regalium));

        console.log(
            "GameStore Implementation:",
            address(gameStoreImplementation)
        );

        console.log(
            "GameStore Proxy:",
            address(store)
        );

        console.log(
            "Presale Implementation:",
            address(presaleImplementation)
        );

        console.log(
            "Presale Proxy:",
            address(presale)
        );

        console.log("========================================");
    }
}