// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./interfaces/IRegaliumToken.sol";

contract RegaliumAccessControl is AccessControl {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant PLAYER_ROLE = keccak256("PLAYER_ROLE");

    constructor(address owner) {
        _grantRole(DEFAULT_ADMIN_ROLE, owner);
        _grantRole(ADMIN_ROLE, owner);
    }

    function grantPlayerRole(address player) external onlyRole(ADMIN_ROLE) {
        _grantRole(PLAYER_ROLE, player);
    }
}
//
