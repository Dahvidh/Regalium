// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import "../src/AccessControl.sol";

error AccessControlUnauthorizedAccount(address account, bytes32 role);

contract RegaliumAccessControlTest is Test {
    RegaliumAccessControl public accessControl;
    address public owner = address(this);
    address public admin = address(0xABCD);
    address public player = address(0xBEEF);

    function setUp() public {
        accessControl = new RegaliumAccessControl(owner);
    }

    function testInitialRoles() public view{
        assertTrue(accessControl.hasRole(accessControl.DEFAULT_ADMIN_ROLE(), owner));
        assertTrue(accessControl.hasRole(accessControl.ADMIN_ROLE(), owner));
    }

    function testGrantPlayerRoleByAdmin() public {
        accessControl.grantRole(accessControl.ADMIN_ROLE(), admin);
        assertTrue(accessControl.hasRole(accessControl.ADMIN_ROLE(), admin));

        vm.prank(admin);
        accessControl.grantPlayerRole(player);
        assertTrue(accessControl.hasRole(accessControl.PLAYER_ROLE(), player));
    }

    function testGrantPlayerRoleRevertsIfNotAdmin() public {
        vm.expectRevert(abi.encodeWithSelector(
            AccessControlUnauthorizedAccount.selector,
            player,
            accessControl.ADMIN_ROLE()
        ));
        vm.prank(player);
        accessControl.grantPlayerRole(player);
    }
}
