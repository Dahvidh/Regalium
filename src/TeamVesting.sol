// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title Regalium Team Vesting
/// @notice Locks the team's RGLM allocation for four years with a one-year cliff.
/// At the cliff, 25% is released; the remaining 75% vests linearly over the next
/// three years. The beneficiary may claim vested tokens at any time.
contract TeamVesting {
    using SafeERC20 for IERC20;

    uint256 public constant CLIFF_DURATION = 365 days;
    uint256 public constant VESTING_DURATION = 4 * 365 days;

    IERC20 public immutable token;
    address public immutable beneficiary;
    uint256 public immutable start;
    uint256 public immutable totalAllocation;
    uint256 public released;

    event TokensReleased(address indexed beneficiary, uint256 amount);

    constructor(IERC20 token_, address beneficiary_, uint256 allocation_) {
        require(address(token_) != address(0), "Invalid token");
        require(beneficiary_ != address(0), "Invalid beneficiary");
        require(allocation_ > 0, "Invalid allocation");

        token = token_;
        beneficiary = beneficiary_;
        totalAllocation = allocation_;
        start = block.timestamp;
    }

    function cliff() public view returns (uint256) {
        return start + CLIFF_DURATION;
    }

    function end() public view returns (uint256) {
        return start + VESTING_DURATION;
    }

    function vestedAmount(uint256 timestamp) public view returns (uint256) {
        if (timestamp < cliff()) return 0;
        if (timestamp >= end()) return totalAllocation;

        uint256 cliffAmount = totalAllocation / 4;
        uint256 remainingDuration = VESTING_DURATION - CLIFF_DURATION;
        uint256 elapsedAfterCliff = timestamp - cliff();

        return cliffAmount + (totalAllocation * elapsedAfterCliff) / remainingDuration;
    }

    function releasable() public view returns (uint256) {
        return vestedAmount(block.timestamp) - released;
    }

    function release() external {
        uint256 amount = releasable();
        require(amount > 0, "No tokens available");

        released += amount;
        token.safeTransfer(beneficiary, amount);

        emit TokensReleased(beneficiary, amount);
    }
}
