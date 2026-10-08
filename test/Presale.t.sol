// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import "../src/RegaliumPresale.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract PresaleMockToken is IERC20 {
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

contract PresaleV2 is Presale {
    uint256 public version;

    function setVersion(uint256 _version) external onlyOwner {
        version = _version;
    }
}

contract PresaleUpgradeableTest is Test {
    Presale public presale;
    PresaleMockToken public token;
    address public owner = address(this);
    address public buyer = address(0xBEEF);
    address public attacker = address(0xBAD);

    /* * The test contract is the treasury because: * * owner = address(this) * * When the Presale sends POL to the treasury, * this contract must be able to receive native currency. */

    receive() external payable {}

    function setUp() public {
        token = new PresaleMockToken();
        Presale implementation = new Presale();
        bytes memory initializationData = abi.encodeCall(Presale.initialize, (address(token), owner));
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initializationData);
        presale = Presale(address(proxy));

        // Give the presale enough RGLM for purchases.

        token.mint(address(presale), 1_000_000e18);

        // Give buyer POL for testing.

        vm.deal(buyer, 100 ether);
    }

    function testInitializesCorrectly() public view {
        assertEq(address(presale.token()), address(token));
        assertEq(presale.owner(), owner);
        assertEq(presale.rate(), 2);
    }

    function testCannotInitializeTwice() public {
        vm.expectRevert();
        presale.initialize(address(token), owner);
    }

    function testPurchaseWorks() public {
        uint256 buyerBalanceBefore = token.balanceOf(buyer);
        vm.prank(buyer);
        presale.buyTokens{value: 1 ether}();
        uint256 buyerBalanceAfter = token.balanceOf(buyer);
        assertEq(buyerBalanceAfter - buyerBalanceBefore, 2 ether);
    }

    function testPurchaseSendsPOLToPresale() public {
        vm.prank(buyer);
        presale.buyTokens{value: 1 ether}();
        assertEq(address(presale).balance, 1 ether);
    }

    function testPurchaseFailsWithNoPOL() public {
        vm.prank(buyer);
        vm.expectRevert("Send POL to buy tokens");
        presale.buyTokens();
    }

    function testPurchaseFailsWhenInsufficientTokens() public {
        uint256 balance = token.balanceOf(address(presale));
        vm.prank(address(presale));
        token.transfer(address(0x1234), balance);
        vm.prank(buyer);
        vm.expectRevert("Not enough tokens in contract");
        presale.buyTokens{value: 1 ether}();
    }

    function testOnlyOwnerCanWithdraw() public {
        vm.prank(buyer);
        vm.expectRevert();
        presale.withdraw();
    }

    function testOwnerCanWithdrawPOL() public {
        vm.prank(buyer);
        presale.buyTokens{value: 1 ether}();
        uint256 ownerBalanceBefore = owner.balance;
        presale.withdraw();
        assertEq(owner.balance, ownerBalanceBefore + 1 ether);
        assertEq(address(presale).balance, 0);
    }

    function testOnlyOwnerCanUpgrade() public {
        PresaleV2 implementationV2 = new PresaleV2();
        vm.prank(attacker);
        vm.expectRevert();
        presale.upgradeToAndCall(address(implementationV2), "");
    }

    function testOwnerCanUpgrade() public {
        PresaleV2 implementationV2 = new PresaleV2();
        presale.upgradeToAndCall(address(implementationV2), "");
        PresaleV2 upgraded = PresaleV2(address(presale));
        upgraded.setVersion(2);
        assertEq(upgraded.version(), 2);
    }

    function testUpgradePreservesStorage() public {
        uint256 originalRate = presale.rate();
        address originalToken = address(presale.token());
        address originalOwner = presale.owner();
        PresaleV2 implementationV2 = new PresaleV2();
        presale.upgradeToAndCall(address(implementationV2), "");
        PresaleV2 upgraded = PresaleV2(address(presale));
        assertEq(upgraded.rate(), originalRate);
        assertEq(address(upgraded.token()), originalToken);
        assertEq(upgraded.owner(), originalOwner);
    }

    function testPurchaseStillWorksAfterUpgrade() public {
        PresaleV2 implementationV2 = new PresaleV2();
        presale.upgradeToAndCall(address(implementationV2), "");
        uint256 beforeBalance = token.balanceOf(buyer);
        vm.prank(buyer);
        presale.buyTokens{value: 1 ether}();
        assertEq(token.balanceOf(buyer), beforeBalance + 2 ether);
    }
}

