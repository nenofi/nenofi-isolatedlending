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
//     address public Bob = address(0x3);
//     address public Charlie = address(0x4);



//     function setUp() public{
//         neIDR = new MockERC20("neRupiah", "neIDR");
//         usdt = new MockERC20("USD Tether", "USDT");
//         isolatedLending = new IsolatedLendingV01(address(usdt), address(neIDR), address(neIDRusdt));
//     }

//     function testAddCollateral() public {
//         vm.startPrank(Alice);
//         usdt.mint(1000e18);
//         usdt.approve(address(isolatedLending), 1000e18);
//         isolatedLending.addCollateral(1000e18);
//         vm.stopPrank();
//         assertEq(isolatedLending.userCollateralAmount(Alice), 1000e18);

//     }

//     function testAddAsset() public {
//         vm.startPrank(Bob);
//         neIDR.mint(10000000e18);
//         neIDR.approve(address(isolatedLending), 10000000e18);
//         isolatedLending.addAsset(1000000e18);
//         vm.stopPrank();
//         assertEq(isolatedLending.balanceOf(address(Bob)), 1000000e18);
//     }

    
//     function testBorrow() public {
//         vm.startPrank(Bob);
//         neIDR.mint(10000000e18);
//         neIDR.approve(address(isolatedLending), 10000000e18);
//         isolatedLending.addAsset(1000000e18);
//         vm.stopPrank();

//         vm.startPrank(Alice);
//         isolatedLending.borrow(1000000e18);
//         vm.stopPrank();

//         console.log(isolatedLending.totalBorrow()/1e18);


//         // assertEq(isolatedLending.balanceOf(address(Bob)), 1000000e18);
//     }


// }