// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.4;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import "../src/IsolatedLendingV02.sol";
import "../src/test/MockERC20.sol";
// import "../src/interface/IOracle.sol";
// import "@solmate/src/tokens/ERC20.sol";


contract IsolatedLendingV02Test is Test {
    IsolatedLendingV02 public isolatedLending;
    ERC20 public neIDR;
    ERC20 public usdt;
    // IOracle public neIDRusdt;

    address public Alice = address(0x2);
    address public Bob = address(0x3);
    address public Charlie = address(0x4);



    function setUp() public{
        neIDR = new MockERC20("neRupiah", "neIDR", 18);
        usdt = new MockERC20("USD Tether", "USDT", 18);
        isolatedLending = new IsolatedLendingV02(neIDR, "neIDR/USDT pair", "neIDR/USDT");
    }

    function testAddAsset() public {
        // vm.startPrank(Bob);
        // console.log(neIDR.x());
        neIDR.mint(1);
        neIDR.approve(address(isolatedLending), 10000000e18);
        // isolatedLending.addAsset(1000000e18);
        // vm.stopPrank();
        // assertEq(isolatedLending.balanceOf(address(Bob)), 1000000e18);
    }

}
