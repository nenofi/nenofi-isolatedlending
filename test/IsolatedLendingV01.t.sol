// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.4;

import "forge-std/Test.sol";
import "../src/IsolatedLendingV01.sol";
import "../src/test/MockERC20.sol";
import "../src/interface/IOracle.sol";


contract IsolatedLendingV01Test is Test {
    IsolatedLendingV01 public isolatedLending;
    MockERC20 public neIDR;
    MockERC20 public usdt;
    IOracle public neIDRusdt;

    function setUp() public{
        neIDR = new MockERC20("neRupiah", "neIDR");
        usdt = new MockERC20("USD Tether", "USDT");
        isolatedLending = new IsolatedLendingV01(address(usdt), address(neIDR), address(neIDRusdt));
    }

    function testAddCollateral(address _to, uint256 _share) public {
        isolatedLending.addCollateral(_to, _share);
        assertEq(isolatedLending.userCollateralShare(_to), _share);
    }

}