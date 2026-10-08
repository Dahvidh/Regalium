// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "chainlink-brownie-contracts/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

contract RegaliumToken is ERC20, Ownable {
    uint256 public constant MAX_SUPPLY = 50_000_000 * 10 ** 18;
    uint256 public constant MATIC_TO_RGLM = 2; // 1 MATIC = 2 RGLM

    AggregatorV3Interface internal maticUsdPriceFeed;

    constructor(address _maticUsdFeed) ERC20("Regalium Token", "RGLM") Ownable(msg.sender) {
        _mint(msg.sender, MAX_SUPPLY);
        maticUsdPriceFeed = AggregatorV3Interface(_maticUsdFeed);
    }

    /// @notice Returns the latest MATIC/USD price from Chainlink
    function getMaticPriceInUSD() public view returns (uint256) {
        (uint80 roundId, int256 price, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) =
            maticUsdPriceFeed.latestRoundData();

        require(roundId > 0, "Invalid oracle round");
        require(price > 0, "Invalid price data");
        require(startedAt > 0, "Missing round start time");
        require(updatedAt > 0, "Missing price timestamp");
        require(answeredInRound >= roundId, "Incomplete price round");

        // Safe because price is positive and fits within uint256.
        // forge-lint: disable-next-line(unsafe-typecast)
        return uint256(price);
    }

    /// @notice Calculates RGLM/USD from MATIC/USD
    /// using the fixed 1 MATIC = 2 RGLM ratio
    function getRglmPriceInUSD() public view returns (uint256) {
        uint256 maticPrice = getMaticPriceInUSD();
        return maticPrice / MATIC_TO_RGLM;
    }

    /// @notice Returns the fixed MATIC/RGLM ratio
    /// 1 MATIC = 2 RGLM
    function getPriceInMatic() public pure returns (uint256) {
        return MATIC_TO_RGLM;
    }
}
