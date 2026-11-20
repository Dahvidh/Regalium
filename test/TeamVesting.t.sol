// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../src/TeamVesting.sol";

contract TeamVestingMockToken is ERC20 {
    constructor() ERC20("Mock RGLM", "mRGLM") {}
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

contract TeamVestingTest is Test {
    TeamVestingMockToken internal token;
    TeamVesting internal vesting;
    address internal beneficiary = address(0xBEEF);
    uint256 internal allocation = 20_000_000 ether;
    uint256 internal startTime = 1_800_000_000;

    function setUp() public {
        vm.warp(startTime);
        token = new TeamVestingMockToken();
        vesting = new TeamVesting(token, beneficiary, allocation);
        token.mint(address(vesting), allocation);
    }

    function testNoTokensVestedBeforeCliff() public view {
        assertEq(vesting.vestedAmount(startTime + 364 days), 0);
        assertEq(vesting.releasable(), 0);
    }

    function testTwentyFivePercentVestsAtOneYearCliff() public {
        vm.warp(startTime + 365 days);
        assertEq(vesting.vestedAmount(block.timestamp), allocation / 4);
        assertEq(vesting.releasable(), allocation / 4);
    }

    function testRemainingSeventyFivePercentVestsLinearlyAfterCliff() public {
        vm.warp(startTime + 365 days + 365 days);
        uint256 expected = allocation / 4 + (allocation * 365 days) / (3 * 365 days);
        assertEq(vesting.vestedAmount(block.timestamp), expected);
    }

    function testBeneficiaryCanReleaseVestedTokens() public {
        vm.warp(startTime + 365 days);
        vm.prank(beneficiary);
        vesting.release();
        assertEq(token.balanceOf(beneficiary), allocation / 4);
        assertEq(vesting.released(), allocation / 4);
    }

    function testCannotReleaseBeforeCliff() public {
        vm.warp(startTime + 364 days);
        vm.expectRevert("No tokens available");
        vesting.release();
    }

    function testAllTokensVestedAfterFourYears() public {
        vm.warp(startTime + 4 * 365 days);
        assertEq(vesting.vestedAmount(block.timestamp), allocation);
        vm.prank(beneficiary);
        vesting.release();
        assertEq(token.balanceOf(beneficiary), allocation);
    }

    function testCannotReleaseMoreThanOnce() public {
        vm.warp(startTime + 4 * 365 days);
        vm.prank(beneficiary);
        vesting.release();
        vm.expectRevert("No tokens available");
        vesting.release();
    }
}
