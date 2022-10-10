// // SPDX-License-Identifier: MIT
// pragma solidity >= 0.8.4;

// import "forge-std/Test.sol";
// import "forge-std/console.sol";

// import "../src/IsolatedLendingV01.sol";
// import "../src/test/MockERC20.sol";
// import "../src/interface/IOracle.sol";


// contract IsolatedLendingV01Test is Test {
//     IsolatedLendingV01 public isolatedLending;
//     MockERC20 public neIDR;
//     MockERC20 public usdt;
//     IOracle public neIDRusdt;

//     address public Alice = address(0x2);

//     function setUp() public{
//         neIDR = new MockERC20("neRupiah", "neIDR");
//         usdt = new MockERC20("USD Tether", "USDT");
//         isolatedLending = new IsolatedLendingV01(address(usdt), address(neIDR), address(neIDRusdt));
//     }

//     function testAddCollateral() public {
//         console.log("HERE");
//         console.log(address(this));
//         vm.startPrank(Alice);
//         usdt.mint(1000e18);
//         console.log(usdt.balanceOf(address(Alice)));
//         usdt.approve(address(isolatedLending), 1000e18);
//         isolatedLending.addCollateral(address(Alice), 1000e18);
//         vm.stopPrank();
//     }

//     function testAccrue() public{
//         isolatedLending.accrue();
//     }

// }