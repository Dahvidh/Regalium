// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import "../src/Regalium.sol";
import "chainlink-brownie-contracts/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

contract MockMaticUsdPriceFeed is AggregatorV3Interface {
    int256 private _price;

    constructor(int256 price_) {
        _price = price_;
    }

    function decimals() external pure override returns (uint8) {
        return 8;
    }

    function description() external pure override returns (string memory) {
        return "Mock MATIC / USD Price Feed";
    }

    function version() external pure override returns (uint256) {
        return 1;
    }

    function getRoundData(uint80 _roundId)
        external
        view
        override
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        return (_roundId, _price, block.timestamp, block.timestamp, _roundId);
    }

    function latestRoundData()
        external
        view
        override
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        return (1, _price, block.timestamp, block.timestamp, 1);
    }
}

contract RegaliumTokenTest is Test {
    RegaliumToken public token;
    MockMaticUsdPriceFeed public priceFeed;

    address public deployer;

    function setUp() public {
        deployer = address(this);

        // Chainlink-style price:
        // 2000 USD × 10^8 = 2000e8
        priceFeed = new MockMaticUsdPriceFeed(2000e8);

        token = new RegaliumToken(address(priceFeed));
    }

    function testTokenNameAndSymbol() public view {
        assertEq(token.name(), "Regalium Token");
        assertEq(token.symbol(), "RGLM");
    }

    function testMaxSupplyIsCorrect() public view {
        uint256 expectedSupply = 50_000_000 * 1e18;

        assertEq(token.totalSupply(), expectedSupply);
    }

    function testDeployerReceivesInitialSupply() public view {
        uint256 expectedSupply = 50_000_000 * 1e18;

        assertEq(token.balanceOf(deployer), expectedSupply);
    }

    function testOwnerIsDeployer() public view {
        assertEq(token.owner(), deployer);
    }

    function testPriceRGLMInMatic() public view {
        uint256 expectedPriceInMatic = 2;

        assertEq(token.getPriceInMatic(), expectedPriceInMatic);
    }

    function testPriceMaticInUsd() public view {
        // Chainlink feeds normally use 8 decimals.
        // 2000 USD = 2000 × 10^8.
        uint256 expectedPriceInUsd = 2000e8;

        assertEq(token.getMaticPriceInUSD(), expectedPriceInUsd);
    }

    function testPriceRGLMInUsd() public view {
        // 1 MATIC = $2,000
        // 2 RGLM = 1 MATIC
        // Therefore 1 RGLM = $1,000.
        uint256 expectedPriceInUsd = 1000e8;

        assertEq(token.getRglmPriceInUSD(), expectedPriceInUsd);
    }
}
