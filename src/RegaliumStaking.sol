// SPDX-License-Identifier: MIT
//staking tokens
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Staking {
    using SafeERC20 for IERC20;

    IERC20 public token;

    mapping(address => uint256) public stakedBalances;
    mapping(address => uint256) public stakeTimestamps;

    uint256 public rewardRatePerSecond = 1e16; // 0.01 token per second

    constructor(address _token) {
        token = IERC20(_token);
    }

    // Stake tokens
    function stake(uint256 amount) external {
        require(amount > 0, "Cannot stake zero");

        if (stakedBalances[msg.sender] > 0) {
            _claimReward(msg.sender);
        }

        token.safeTransferFrom(msg.sender, address(this), amount);
        stakedBalances[msg.sender] += amount;
        stakeTimestamps[msg.sender] = block.timestamp;
    }

    // Unstake tokens
    function unstake(uint256 amount) external {
        require(amount > 0, "Cannot unstake zero");
        require(stakedBalances[msg.sender] >= amount, "Not enough staked");

        _claimReward(msg.sender);

        stakedBalances[msg.sender] -= amount;
        token.safeTransfer(msg.sender, amount);

        if (stakedBalances[msg.sender] == 0) {
            stakeTimestamps[msg.sender] = 0;
        } else {
            stakeTimestamps[msg.sender] = block.timestamp;
        }
    }

    // Claim only rewards
    function claimReward() external {
        _claimReward(msg.sender);
        stakeTimestamps[msg.sender] = block.timestamp;
    }

    // Internal: Calculate and transfer reward from pool
    function _claimReward(address user) internal {
        uint256 reward = calculateReward(user);
       uint256 poolBalance = token.balanceOf(address(this)) - stakedBalances[user];


        if (reward > 0 && poolBalance >= reward) {
            token.safeTransfer(user, reward);
        }
    }

    // Public view: Calculate reward
    function calculateReward(address user) public view returns (uint256) {
        uint256 staked = stakedBalances[user];
        uint256 lastTimestamp = stakeTimestamps[user];

        if (staked == 0 || lastTimestamp == 0) {
            return 0;
        }

        uint256 duration = block.timestamp - lastTimestamp;
        return (staked * rewardRatePerSecond * duration) / 1e18;
    }
}
    // Admin: Set Reward Rate Per Second
    //function setRewardRatePerSecond(uint256 _rewardRatePerSecond) external {
      //  require(_rewardRatePerSecond > 0, "Cannot set zero");
        // rewardRatePerSecond = _rewardRatePerSecond;
   // }
    // Admin: Fund the reward pool (no function needed, just send tokens to contract)
