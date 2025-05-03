// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import "../src/Regalium.sol";

contract RegaliumTokenTest is Test {
    RegaliumToken public token;
    address public deployer;

    function setUp() public {
        deployer = address(this);
        token = new RegaliumToken(address(0xd9FFdb71EbE7496cC440152d43986Aae0AB76665)); //  price feed address
    }

    function testTokenNameAndSymbol() public view{
        assertEq(token.name(), "Regalium Token");
        assertEq(token.symbol(), "RGLM");
    }

    function testMaxSupplyIsCorrect() public view{
        uint256 expectedSupply = 50_000_000 * 1e18;
        assertEq(token.totalSupply(), expectedSupply);
    }

    function testDeployerReceivesInitialSupply() public view{
        uint256 expectedSupply = 50_000_000 * 1e18;
        assertEq(token.balanceOf(deployer), expectedSupply);
    }

    function testOwnerIsDeployer() public view {
        assertEq(token.owner(), deployer);
    }

    function testPriceRGLMInMatic() public view{
        uint256 expectedPriceInMatic = 2; // 1 MATIC = 2 RGLM
        assertEq(token.getPriceInMatic(), expectedPriceInMatic);
    }

   function testPriceMaticInUsd() public view{
        uint256 expectedPriceInUsd = 2000; // Assuming 1 MATIC = 2k USD 
       assertEq(token.getMaticPriceInUSD(), expectedPriceInUsd);
   }

   // function testPriceRGLMInUsd() public view{
       // uint256 expectedPriceInUsd = 1000; // Assume 1 RGLM = 1k USD 
       // assertEq(token.getRglmPriceInUSD(), expectedPriceInUsd);
    //}
}
