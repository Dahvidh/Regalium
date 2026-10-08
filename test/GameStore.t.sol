// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import "../src/RegaliumGameStore.sol";

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract GameStoreMockToken is IERC20 {
    mapping(address => uint256) public override balanceOf;
    mapping(address => mapping(address => uint256)) public override allowance;
    uint256 public override totalSupply;

    function transfer(address to, uint256 amount) external override returns (bool) {
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external override returns (bool) {
        allowance[from][msg.sender] -= amount;
        balanceOf[from] -= amount;
        balanceOf[to] += amount;

        emit Transfer(from, to, amount);

        return true;
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function mint(address to, uint256 amount) external {
        balanceOf[to] += amount;
        totalSupply += amount;

        emit Transfer(address(0), to, amount);
    }
}

contract GameStoreV2 is GameStore {
    uint256 public version;

    function setVersion(uint256 _version) external onlyOwner {
        version = _version;
    }
}

contract GameStoreUpgradeableTest is Test {
    GameStore public store;
    GameStoreMockToken public token;

    address public owner = address(this);
    address public player = address(0xBEEF);
    address public attacker = address(0xBAD);

    function setUp() public {
        token = new GameStoreMockToken();

        GameStore implementation = new GameStore();

        bytes memory initializationData = abi.encodeCall(GameStore.initialize, (address(token), owner));

        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initializationData);

        store = GameStore(address(proxy));

        // Fund GameStore with RGLM.
        token.mint(address(store), 1_000_000e18);
    }

    function testInitializesCorrectly() public view {
        assertEq(address(store.token()), address(token));

        assertEq(store.owner(), owner);
    }

    function testCannotInitializeTwice() public {
        vm.expectRevert();

        store.initialize(address(token), owner);
    }

    function testOnlyOwnerCanRewardUser() public {
        vm.prank(attacker);

        vm.expectRevert();

        store.rewardUser(player, 100e18);
    }

    function testOwnerCanRewardPlayer() public {
        store.rewardUser(player, 100e18);

        assertEq(store.rewards(player), 100e18);
    }

    function testMultipleRewardsAccumulate() public {
        store.rewardUser(player, 100e18);

        store.rewardUser(player, 50e18);

        assertEq(store.rewards(player), 150e18);
    }

    function testPlayerCanWithdrawRewards() public {
        store.rewardUser(player, 100e18);

        uint256 beforeBalance = token.balanceOf(player);

        vm.prank(player);

        store.withdraw();

        assertEq(token.balanceOf(player), beforeBalance + 100e18);

        assertEq(store.rewards(player), 0);
    }

    function testWithdrawFailsWithoutRewards() public {
        vm.prank(player);

        vm.expectRevert("No rewards to withdraw");

        store.withdraw();
    }

    function testRewardCannotUseZeroAddress() public {
        vm.expectRevert("Invalid user");

        store.rewardUser(address(0), 100e18);
    }

    function testRewardCannotBeZero() public {
        vm.expectRevert("Invalid amount");

        store.rewardUser(player, 0);
    }

    function testOnlyOwnerCanUpgrade() public {
        GameStoreV2 implementationV2 = new GameStoreV2();

        vm.prank(attacker);

        vm.expectRevert();

        store.upgradeToAndCall(address(implementationV2), "");
    }

    function testOwnerCanUpgrade() public {
        GameStoreV2 implementationV2 = new GameStoreV2();

        store.upgradeToAndCall(address(implementationV2), "");

        GameStoreV2 upgraded = GameStoreV2(address(store));

        upgraded.setVersion(2);

        assertEq(upgraded.version(), 2);
    }

    function testRewardsSurviveUpgrade() public {
        store.rewardUser(player, 500e18);

        GameStoreV2 implementationV2 = new GameStoreV2();

        store.upgradeToAndCall(address(implementationV2), "");

        GameStoreV2 upgraded = GameStoreV2(address(store));

        assertEq(upgraded.rewards(player), 500e18);
    }

    function testPlayerCanWithdrawAfterUpgrade() public {
        store.rewardUser(player, 500e18);

        GameStoreV2 implementationV2 = new GameStoreV2();

        store.upgradeToAndCall(address(implementationV2), "");

        uint256 beforeBalance = token.balanceOf(player);

        vm.prank(player);

        GameStore(address(store)).withdraw();

        assertEq(token.balanceOf(player), beforeBalance + 500e18);

        assertEq(GameStore(address(store)).rewards(player), 0);
    }
}
