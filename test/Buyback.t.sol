// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import "../src/RegaliumBuyback.sol";
import "../src/interfaces/IRegaliumToken.sol";

 contract MockRegaliumToken is IRegaliumToken {
    mapping(address => uint256) public override balanceOf;
    mapping(address => mapping(address => uint256)) public override allowance;

    event TransferFromCalled(address from, address to, uint256 amount);
    event BurnFromCalled(address account, uint256 amount);

    function transferFrom(address from, address to, uint256 amount) external override returns (bool) {
        emit TransferFromCalled(from, to, amount);
        return true;
    }

    function burnFrom(address account, uint256 amount) external override {
        emit BurnFromCalled(account, amount);
    }

    // Other IERC20-required functions (optional stubs for completeness)
    function totalSupply() external pure override returns (uint256) { return 0; }
    function transfer(address, uint256) external pure override returns (bool) { return true; }
    function approve(address, uint256) external pure override returns (bool) { return true; }
}

contract BuybackTest is Test {
    Buyback public buyback;
    MockRegaliumToken public mockToken;
    address public user = address(0xABCD);

    // ✅ Redefine events locally to allow `emit` usage
    event TransferFromCalled(address from, address to, uint256 amount);
    event BurnFromCalled(address account, uint256 amount);

    function setUp() public {
        mockToken = new MockRegaliumToken();
        buyback = new Buyback(address(mockToken));
    }

    function testBuybackCallsTransferFromAndBurnFrom() public {
        vm.startPrank(user);

        vm.expectEmit(true, true, true, true);
        emit TransferFromCalled(user, address(buyback), 100e18);

        vm.expectEmit(true, true, true, true);
        emit BurnFromCalled(address(buyback), 100e18);

        buyback.buyback(100e18);
        vm.stopPrank();
    }

    function testTokenIsSetCorrectly() public view{
        assertEq(address(buyback.token()), address(mockToken));
    }
}
