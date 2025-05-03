// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IRegaliumToken.sol";

contract Buyback {
    IRegaliumToken public token;

    constructor(address _token) {
        token = IRegaliumToken(_token);
    }

    function buyback(uint256 amount) external {
        token.transferFrom(msg.sender, address(this), amount);
        token.burnFrom(address(this), amount);
        // send MATIC or other token as refund
    }
}