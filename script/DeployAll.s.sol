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

        // Configure the presale inventory in whole RGLM tokens.
        // Read this before broadcasting so a missing/invalid value cannot
        // leave a partially deployed set of contracts.
        uint256 presaleAllocation = vm.envUint("PRESALE_ALLOCATION");
        require(presaleAllocation > 0, "PRESALE_ALLOCATION must be greater than zero");
        require(
            presaleAllocation <= 50_000_000,
            "PRESALE_ALLOCATION exceeds MAX_SUPPLY"
        );
        uint256 presaleFunding = presaleAllocation * 1e18;

        vm.startBroadcast(deployerPrivateKey);

        // Chainlink MATIC/USD feed.
        // Verify this address is correct for the target network before deployment.
        address maticUsdFeed =
            0x565Ffe93b3b9EF5Ffc0e0e3ee2b6B7f43f31ff29;

        // ---------------------------------------------------------
        // 1. Deploy RegaliumToken
        // ---------------------------------------------------------

        RegaliumToken regalium = new RegaliumToken(maticUsdFeed);

        // ---------------------------------------------------------
        // 2. Deploy GameStore implementation and proxy
        // ---------------------------------------------------------

        GameStore gameStoreImplementation = new GameStore();

        bytes memory gameStoreInitData = abi.encodeCall(
            GameStore.initialize,
            (address(regalium), deployer)
        );

        ERC1967Proxy gameStoreProxy = new ERC1967Proxy(
            address(gameStoreImplementation),
            gameStoreInitData
        );

        GameStore store = GameStore(address(gameStoreProxy));

        // ---------------------------------------------------------
        // 3. Deploy Presale implementation and proxy
        // ---------------------------------------------------------

        Presale presaleImplementation = new Presale();

        bytes memory presaleInitData = abi.encodeCall(
            Presale.initialize,
            (address(regalium), deployer)
        );

        ERC1967Proxy presaleProxy = new ERC1967Proxy(
            address(presaleImplementation),
            presaleInitData
        );

        Presale presale = Presale(address(presaleProxy));

        // ---------------------------------------------------------
        // 4. Fund the Presale before deployment completes
        // ---------------------------------------------------------

        require(
            regalium.transfer(address(presale), presaleFunding),
            "Presale token funding transfer failed"
        );
        require(
            regalium.balanceOf(address(presale)) == presaleFunding,
            "Presale inventory verification failed"
        );

        vm.stopBroadcast();

        // ---------------------------------------------------------
        // Deployment information
        // ---------------------------------------------------------

        console.log("========================================");
        console.log("Regalium Deployment Complete");
        console.log("========================================");

        console.log("Deployer:", deployer);
        console.log("Regalium Token:", address(regalium));
        console.log("GameStore Implementation:", address(gameStoreImplementation));
        console.log("GameStore Proxy:", address(store));
        console.log("Presale Implementation:", address(presaleImplementation));
        console.log("Presale Proxy:", address(presale));
        console.log("Presale allocation (RGLM):", presaleAllocation);
        console.log("Verified Presale inventory (wei):", regalium.balanceOf(address(presale)));

        console.log("========================================");
    }
}