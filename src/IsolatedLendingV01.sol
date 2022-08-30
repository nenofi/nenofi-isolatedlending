// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interface/IOracle.sol";

contract IsolatedLendingV01{

    IERC20 public collateral;
    IERC20 public asset;
    IOracle public oracle;

    uint256 public totalCollateralShare;

    //user balances
    mapping(address => uint256) public userCollateralShare;
    // userAssetFraction is called balanceOf for ERC20 compatibility (it's in ERC20.sol)
    mapping(address => uint256) public userBorrowPart;

    uint256 public exchangeRate;

    constructor(address _collateral, address _asset){
        collateral = IERC20(_collateral);
        asset = IERC20(_asset);
    }
    

}