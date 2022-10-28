// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.4;

import "solmate/mixins/ERC4626.sol";

contract IsolatedLendingV02 is ERC4626{

    constructor(ERC20 _asset, string memory _name, string memory _symbol)ERC4626(_asset, _name, _symbol){
    }

    function totalAssets() public override view virtual returns (uint256){
        return asset.balanceOf(address(this));
    }

    
    
}
