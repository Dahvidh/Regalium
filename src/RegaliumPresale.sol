// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Presale {
    IERC20 public token;
    uint256 public rate = 2; // 1 MATIC = 2 RGLM
    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }

    constructor(address _token) {
        token = IERC20(_token);
        owner = msg.sender;
    }

    function buyTokens() external payable {
        require(msg.value > 0, "Send MATIC to buy tokens");

        uint256 tokenAmount = msg.value * rate;
        
        require(token.balanceOf(address(this)) >= tokenAmount, "Not enough tokens in contract");

        bool success = token.transfer(msg.sender, tokenAmount);
        require(success, "Token transfer failed");
    }

    // Withdraw all collected MATIC to the owner's wallet
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No MATIC to withdraw");

        (bool sent, ) = owner.call{value: balance}("");
        require(sent, "Failed to send MATIC");
    }
}
