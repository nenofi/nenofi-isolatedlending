// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interface/IOracle.sol";


contract IsolatedLendingV01{

    address public feeTo;

    IERC20 public collateral;
    IERC20 public asset;
    IOracle public oracle;

    // Total amounts
    uint256 public totalCollateralShare; // Total collateral supplied
    uint256 public totalAssetBase;
    uint256 public totalBorrowBase;
    uint256 public totalBorrowElastic;

    //user balances
    mapping(address => uint256) public userCollateralShare;
    // userAssetFraction is called balanceOf for ERC20 compatibility (it's in ERC20.sol)
    mapping(address => uint256) public userBorrowPart;

    uint256 public exchangeRate;

    struct AccrueInfo {
        uint64 interestPerSecond;
        uint64 lastAccrued;
        uint128 feesEarnedFraction;
    }

    AccrueInfo public accrueInfo;


    constructor(address _collateral, address _asset, address _oracle){
        feeTo = 0xC69bf0B2F5862650aEB94024Fa7D7187c53c69Fd;
        collateral = IERC20(_collateral);
        asset = IERC20(_asset);
        oracle = IOracle(_oracle);
    }

    function accrue() public{
        AccrueInfo memory _accrueInfo = accrueInfo;
        // Number of seconds since accrue was called
        uint256 elapsedTime = block.timestamp - _accrueInfo.lastAccrued;
        if (elapsedTime == 0) {
            return;
        }
        _accrueInfo.lastAccrued = uint64(block.timestamp);

        uint256 _totalBorrowBase = totalBorrowBase;
        uint256 _totalBorrowElastic = totalBorrowElastic;

        if(_totalBorrowBase == 0){
            if (_accrueInfo.interestPerSecond != 0) {
                _accrueInfo.interestPerSecond = 0;
            }
            accrueInfo = _accrueInfo;
            return;
        }

        uint256 extraAmount = 0;
        uint256 feeFraction = 0;
        uint256 _totalAssetBase = totalAssetBase;
        uint256 _totalAssetElastic = totalAssetElastic;


        // Accrue interest
        extraAmount = _totalBorrowElastic*_accrueInfo.interestPerSecond*elapsedTime / 1e18;
        _totalBorrowElastic = _totalBorrowElastic + extraAmount;
        uint256 fullAssetAmount = _totalAssetElastic +  _totalBorrowElastic;

        uint256 feeAmount = extraAmount * 10000/1e5; // % of interest paid goes to fee
        feeFraction = feeAmount*_totalAssetBase / fullAssetAmount;
        _accrueInfo.feesEarnedFraction = _accrueInfo.feesEarnedFraction + feeFraction;
        totalAssetBase = totalAssetBase + feeFraction;

        //update interest rate

        accrueInfo = _accrueInfo;
    }

    function addCollateral(address _to, uint256 _share) public {
        userCollateralShare[_to] += userCollateralShare[_to] + _share;
        uint256 oldTotalCollateralShare = totalCollateralShare;
        totalCollateralShare += oldTotalCollateralShare + _share;
    }
    

}