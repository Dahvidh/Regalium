// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IRegaliumToken.sol";

contract GameStore {
    IRegaliumToken public token;
    address public owner;

    // Track how much each player can withdraw
    mapping(address => uint256) public rewards;

    event RewardWithdrawn(address indexed user, uint256 amount); // ✅ New event

    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }

    constructor(address _token) {
        token = IRegaliumToken(_token);
        owner = msg.sender;
    }

    // Called by the game server to reward players
    function rewardUser(address user, uint256 amount) external onlyOwner {
        rewards[user] += amount;
    }

    // Players can call this to withdraw their earned tokens
    function withdraw() external {
        uint256 amount = rewards[msg.sender];
        require(amount > 0, "No rewards to withdraw");

        rewards[msg.sender] = 0; // Prevent re-entrancy
        require(token.transfer(msg.sender, amount), "Token transfer failed");

        emit RewardWithdrawn(msg.sender, amount); // ✅ Emit the event
    }
}
