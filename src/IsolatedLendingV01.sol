// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./interface/IOracle.sol";
// import "@boringcrypto/contracts/libraries/BoringERC20.sol";

struct Rebase {
    uint256 elastic;
    uint256 base;
}

/// @notice A rebasing library using overflow-/underflow-safe math.
library RebaseLibrary {
    /// @notice Calculates the base value in relationship to `elastic` and `total`.
    function toBase(
        Rebase memory total,
        uint256 elastic,
        bool roundUp
    ) internal pure returns (uint256 base) {
        if (total.elastic == 0) {
            base = elastic;
        } else {
            base = (elastic * total.base) / total.elastic;
            if (roundUp && (base * total.elastic) / total.base < elastic) {
                base++;
            }
        }
    }

    /// @notice Calculates the elastic value in relationship to `base` and `total`.
    function toElastic(
        Rebase memory total,
        uint256 base,
        bool roundUp
    ) internal pure returns (uint256 elastic) {
        if (total.base == 0) {
            elastic = base;
        } else {
            elastic = (base * total.elastic) / total.base;
            if (roundUp && (elastic * total.base) / total.elastic < base) {
                elastic++;
            }
        }
    }

    /// @notice Add `elastic` to `total` and doubles `total.base`.
    /// @return (Rebase) The new total.
    /// @return base in relationship to `elastic`.
    function add(
        Rebase memory total,
        uint256 elastic,
        bool roundUp
    ) internal pure returns (Rebase memory, uint256 base) {
        base = toBase(total, elastic, roundUp);
        total.elastic += elastic;
        total.base += base;
        return (total, base);
    }

    /// @notice Sub `base` from `total` and update `total.elastic`.
    /// @return (Rebase) The new total.
    /// @return elastic in relationship to `base`.
    function sub(
        Rebase memory total,
        uint256 base,
        bool roundUp
    ) internal pure returns (Rebase memory, uint256 elastic) {
        elastic = toElastic(total, base, roundUp);
        total.elastic -= elastic;
        total.base -= base;
        return (total, elastic);
    }

    /// @notice Add `elastic` and `base` to `total`.
    function add(
        Rebase memory total,
        uint256 elastic,
        uint256 base
    ) internal pure returns (Rebase memory) {
        total.elastic += elastic;
        total.base += base;
        return total;
    }

    /// @notice Subtract `elastic` and `base` to `total`.
    function sub(
        Rebase memory total,
        uint256 elastic,
        uint256 base
    ) internal pure returns (Rebase memory) {
        total.elastic -= elastic;
        total.base -= base;
        return total;
    }

    /// @notice Add `elastic` to `total` and update storage.
    /// @return newElastic Returns updated `elastic`.
    function addElastic(Rebase storage total, uint256 elastic) internal returns (uint256 newElastic) {
        newElastic = total.elastic += elastic;
    }

    /// @notice Subtract `elastic` from `total` and update storage.
    /// @return newElastic Returns updated `elastic`.
    function subElastic(Rebase storage total, uint256 elastic) internal returns (uint256 newElastic) {
        newElastic = total.elastic -= elastic;
    }
}


contract IsolatedLendingV01 is ERC20{
    using RebaseLibrary for Rebase;

    address public feeTo;

    IERC20 public collateral;
    IERC20 public asset;
    IOracle public oracle;

    // Total amounts
    uint256 public totalCollateralAmount; // Total collateral supplied
    uint256 public totalAsset;
    uint256 public totalBorrow;
    // Rebase public totalAsset; // total Asset available to borrow. elastic = BentoBox shares held by the KashiPair, base = Total fractions/percentage held by asset suppliers
    // totalAsset.elastic shouldnt be used
    // Rebase public totalBorrow; // elastic = Total token amount to be repayed by borrowers, base = Total parts of the debt held by borrowers

    //user balances
    mapping(address => uint256) public userCollateralAmount;
    // userAssetFraction is called balanceOf for ERC20 compatibility (it's in ERC20.sol)
    mapping(address => uint256) public userBorrowAmount;

    uint256 public exchangeRate;
    uint256 public ibTokenRate;

    struct AccrueInfo {
        uint256 interestPerSecond;
        uint256 lastAccrued;
        uint256 feesEarnedFraction;
    }

    AccrueInfo public accrueInfo;

    // Settings for the Medium Risk KashiPair
    uint256 private constant CLOSED_COLLATERIZATION_RATE = 75000; // 75%
    uint256 private constant OPEN_COLLATERIZATION_RATE = 77000; // 77%
    uint256 private constant COLLATERIZATION_RATE_PRECISION = 1e5; // Must be less than EXCHANGE_RATE_PRECISION (due to optimization in math)
    uint256 private constant MINIMUM_TARGET_UTILIZATION = 7e17; // 70%
    uint256 private constant MAXIMUM_TARGET_UTILIZATION = 8e17; // 80%
    uint256 private constant UTILIZATION_PRECISION = 1e18;
    uint256 private constant FULL_UTILIZATION = 1e18;
    uint256 private constant FULL_UTILIZATION_MINUS_MAX = FULL_UTILIZATION - MAXIMUM_TARGET_UTILIZATION;
    uint256 private constant FACTOR_PRECISION = 1e18;

    uint64 private constant STARTING_INTEREST_PER_SECOND = 317097920; // approx 1% APR
    uint64 private constant MINIMUM_INTEREST_PER_SECOND = 79274480; // approx 0.25% APR
    uint64 private constant MAXIMUM_INTEREST_PER_SECOND = 317097920000; // approx 1000% APR
    uint256 private constant INTEREST_ELASTICITY = 28800e36; // Half or double in 28800 seconds (8 hours) if linear

    uint256 private constant EXCHANGE_RATE_PRECISION = 1e18;

    uint256 private constant LIQUIDATION_MULTIPLIER = 112000; // add 12%
    uint256 private constant LIQUIDATION_MULTIPLIER_PRECISION = 1e5;

    // Fees
    uint256 private constant PROTOCOL_FEE = 10000; // 10%
    uint256 private constant PROTOCOL_FEE_DIVISOR = 1e5;
    uint256 private constant BORROW_OPENING_FEE = 50; // 0.05%
    uint256 private constant BORROW_OPENING_FEE_PRECISION = 1e5;



    constructor(address _collateral, address _asset, address _oracle)ERC20("USDT/NEIDR","USDT/NEIDR ibNeIDR"){
        feeTo = 0xC69bf0B2F5862650aEB94024Fa7D7187c53c69Fd;
        collateral = IERC20(_collateral);
        asset = IERC20(_asset);
        oracle = IOracle(_oracle);
        accrueInfo.interestPerSecond = uint64(STARTING_INTEREST_PER_SECOND); // 1% APR, with 1e18 being 100%
        ibTokenRate = 1e18;
    }

    // function accrue() public{
    //     AccrueInfo memory _accrueInfo = accrueInfo;
    //     // Number of seconds since accrue was called
    //     uint256 elapsedTime = block.timestamp - _accrueInfo.lastAccrued;
    //     if (elapsedTime == 0) {
    //         return;
    //     }
    //     _accrueInfo.lastAccrued = block.timestamp;

    //     Rebase memory _totalBorrow = totalBorrow;

    //     if(_totalBorrow.base == 0){
    //         if (_accrueInfo.interestPerSecond != STARTING_INTEREST_PER_SECOND) {
    //             _accrueInfo.interestPerSecond = STARTING_INTEREST_PER_SECOND;
    //         }
    //         accrueInfo = _accrueInfo;
    //         return;
    //     }

    //     uint256 extraAmount = 0;
    //     uint256 feeFraction = 0;
    //     Rebase memory _totalAsset = totalAsset;

    //     // Accrue interest
    //     extraAmount = _totalBorrow.elastic*_accrueInfo.interestPerSecond*elapsedTime / 1e18;
    //     _totalBorrow.elastic = _totalBorrow.elastic + extraAmount;
    //     uint256 fullAssetAmount = _totalAsset.toElastic(_totalAsset.elastic,false) + _totalBorrow.elastic;

    //     uint256 feeAmount = extraAmount * 10000/1e5; // % of interest paid goes to fee
    //     feeFraction = feeAmount*_totalAsset.base / fullAssetAmount;
    //     _accrueInfo.feesEarnedFraction = _accrueInfo.feesEarnedFraction + feeFraction;
    //     totalAsset.base = totalAsset.base + feeFraction;
    //     totalBorrow = _totalBorrow;

    //     //update interest rate
    //     uint256 utilization = _totalBorrow.elastic*(1e18) / fullAssetAmount;
    //     if (utilization < MINIMUM_TARGET_UTILIZATION) {
    //         uint256 underFactor = (MINIMUM_TARGET_UTILIZATION-utilization)*FACTOR_PRECISION / MINIMUM_TARGET_UTILIZATION;
    //         uint256 scale = INTEREST_ELASTICITY+(underFactor*underFactor*elapsedTime);
    //         _accrueInfo.interestPerSecond = _accrueInfo.interestPerSecond*INTEREST_ELASTICITY / scale;

    //         if (_accrueInfo.interestPerSecond < MINIMUM_INTEREST_PER_SECOND) {
    //             _accrueInfo.interestPerSecond = MINIMUM_INTEREST_PER_SECOND; // 0.25% APR minimum
    //         }
    //     } else if (utilization > MAXIMUM_TARGET_UTILIZATION) {
    //         uint256 overFactor = (utilization-MAXIMUM_TARGET_UTILIZATION)*FACTOR_PRECISION / FULL_UTILIZATION_MINUS_MAX;
    //         uint256 scale = INTEREST_ELASTICITY+(overFactor*overFactor*elapsedTime);
    //         uint256 newInterestPerSecond = _accrueInfo.interestPerSecond*scale / INTEREST_ELASTICITY;
    //         if (newInterestPerSecond > MAXIMUM_INTEREST_PER_SECOND) {
    //             newInterestPerSecond = MAXIMUM_INTEREST_PER_SECOND; // 1000% APR maximum
    //         }
    //         _accrueInfo.interestPerSecond = uint64(newInterestPerSecond);
    //     }

    //     accrueInfo = _accrueInfo;
    // }
    
    // function _addTokens(IERC20 _token, uint256 _share){
    //     _token.transferFrom()
    // }
    
    function _borrow(uint256 _amount) internal{
        uint256 feeAmount = _amount*(BORROW_OPENING_FEE) / BORROW_OPENING_FEE_PRECISION; // A flat % fee is charged for any borrow
        userBorrowAmount[msg.sender] += _amount + feeAmount;
        totalBorrow = userBorrowAmount[msg.sender];
        totalAsset -= _amount;
        asset.transfer(msg.sender, _amount);
    }

    function borrow(uint256 _amount) public{
        _borrow(_amount);
    }

    function addCollateral(uint256 _amount) public {
        userCollateralAmount[msg.sender] += userCollateralAmount[msg.sender] + _amount;
        totalCollateralAmount += totalCollateralAmount + _amount;
        collateral.transferFrom(msg.sender, address(this), _amount);
    }

    // integrate ibTokenRate to mint the share
    function _addAsset(uint256 _amount) internal returns (uint256 shares) {
        uint256 _pool = balance();
        asset.transferFrom(msg.sender, address(this), _amount);
        totalAsset += _amount;
        uint256 _after = balance();
        _amount = _after - _pool;
        shares = 0;
        if(totalSupply() == 0){
            shares = _amount;
        } else{
            shares = (_amount*totalSupply())/(_pool); //*auto revert if funds are all utilized and a user tried to deposit
        }
        _mint(msg.sender, shares);
    }

    // function _addAsset(address _to, uint256 _share) internal returns (uint256 fraction) {
    //     Rebase memory _totalAsset = totalAsset;
    //     // uint256 totalAssetShare = _totalAsset.elastic;
    //     uint256 allShare = _totalAsset.elastic;
    //     fraction = allShare == 0 ? _share : _share*_totalAsset.base / allShare;
    //     if (_totalAsset.base+fraction < 1000) {
    //         return 0;
    //     }
    //     totalAsset = _totalAsset.add(_share, fraction);
    //     // balanceOf[_to] += balanceOf[_to] + fraction;
    //     _mint(_to, fraction);
    //     asset.transferFrom(_to, address(this), _share);
    // }

    function addAsset(uint256 _amount)public returns (uint256 shares){
        // accrue();
        shares = _addAsset(_amount);
    }

    function balance() public view returns(uint){
        return IERC20(asset).balanceOf(address(this));
    }

}