// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IRegaliumToken is IERC20 {
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function burnFrom(address account, uint256 amount) external;
}
