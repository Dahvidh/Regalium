// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Script.sol";
import "forge-std/console.sol";

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {RegaliumToken} from "src/Regalium.sol";
import {GameStore} from "src/RegaliumGameStore.sol";
import {Presale} from "src/RegaliumPresale.sol";
import {TeamVesting} from "src/TeamVesting.sol";

contract DeployAll is Script {
    uint256 internal constant TOKEN_UNIT = 1e18;
    uint256 internal constant MAX_SUPPLY = 100_000_000;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        // Preserve the approved 40% / 40% / 20% allocation ratio.
        uint256 teamAllocation = vm.envUint("TEAM_ALLOCATION");
        uint256 gameStoreAllocation = vm.envUint("GAMESTORE_ALLOCATION");
        uint256 presaleAllocation = vm.envUint("PRESALE_ALLOCATION");
        address teamBeneficiary = vm.envAddress("TEAM_BENEFICIARY");

        require(teamBeneficiary != address(0), "Invalid team beneficiary");
        require(teamAllocation > 0, "TEAM_ALLOCATION must be greater than zero");
        require(gameStoreAllocation > 0, "GAMESTORE_ALLOCATION must be greater than zero");
        require(presaleAllocation > 0, "PRESALE_ALLOCATION must be greater than zero");
        require(
            teamAllocation + gameStoreAllocation + presaleAllocation == MAX_SUPPLY,
            "Allocations must total MAX_SUPPLY"
        );
        require(
            teamAllocation == 40_000_000 &&
                gameStoreAllocation == 40_000_000 &&
                presaleAllocation == 20_000_000,
            "Allocations must preserve 40/40/20 split"
        );

        uint256 teamFunding = teamAllocation * TOKEN_UNIT;
        uint256 gameStoreFunding = gameStoreAllocation * TOKEN_UNIT;
        uint256 presaleFunding = presaleAllocation * TOKEN_UNIT;

        vm.startBroadcast(deployerPrivateKey);

        // Chainlink MATIC/USD feed. Verify for the target network before deployment.
        address maticUsdFeed = 0x565Ffe93b3b9EF5Ffc0e0e3ee2b6B7f43f31ff29;

        // 1. Deploy the fixed-supply token. The deployer initially receives all 100m.
        RegaliumToken regalium = new RegaliumToken(maticUsdFeed);

        // 2. Deploy GameStore implementation and proxy.
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

        // 3. Deploy Presale implementation and proxy.
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

        // 4. Deploy the team's four-year vesting vault with a one-year cliff.
        TeamVesting teamVesting = new TeamVesting(
            IERC20(address(regalium)),
            teamBeneficiary,
            teamFunding
        );

        // 5. Distribute the complete fixed supply and verify every destination.
        require(
            regalium.transfer(address(teamVesting), teamFunding),
            "Team vesting funding failed"
        );
        require(
            regalium.transfer(address(store), gameStoreFunding),
            "GameStore funding failed"
        );
        require(
            regalium.transfer(address(presale), presaleFunding),
            "Presale funding failed"
        );

        require(
            regalium.balanceOf(address(teamVesting)) == teamFunding,
            "Team vesting balance verification failed"
        );
        require(
            regalium.balanceOf(address(store)) == gameStoreFunding,
            "GameStore balance verification failed"
        );
        require(
            regalium.balanceOf(address(presale)) == presaleFunding,
            "Presale balance verification failed"
        );
        require(regalium.balanceOf(deployer) == 0, "Undistributed tokens remain");

        vm.stopBroadcast();

        console.log("========================================");
        console.log("Regalium Deployment Complete");
        console.log("========================================");
        console.log("Deployer:", deployer);
        console.log("Regalium Token:", address(regalium));
        console.log("GameStore Implementation:", address(gameStoreImplementation));
        console.log("GameStore Proxy:", address(store));
        console.log("Presale Implementation:", address(presaleImplementation));
        console.log("Presale Proxy:", address(presale));
        console.log("Team Vesting Contract:", address(teamVesting));
        console.log("Team Beneficiary:", teamBeneficiary);
        console.log("Total supply (RGLM):", MAX_SUPPLY);
        console.log("Team allocation (RGLM):", teamAllocation);
        console.log("GameStore allocation (RGLM):", gameStoreAllocation);
        console.log("Presale allocation (RGLM):", presaleAllocation);
        console.log("Verified Team Vesting balance:", regalium.balanceOf(address(teamVesting)));
        console.log("Verified GameStore balance:", regalium.balanceOf(address(store)));
        console.log("Verified Presale balance:", regalium.balanceOf(address(presale)));
        console.log("Team cliff timestamp:", teamVesting.cliff());
        console.log("Team vesting end timestamp:", teamVesting.end());
        console.log("========================================");
    }
}
