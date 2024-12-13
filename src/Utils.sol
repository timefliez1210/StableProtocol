//SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import {MockOracle} from "./mocks/MockOracle.sol";

abstract contract Utils is MockOracle {
    error NotOwner(address);

    address public constant ETHER = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    uint256 public constant MIN_DEPOSIT_ETH = 1e6;
    address owner;

    mapping(address asset => bool isAllowed) public s_whitelist;
    // @todo have a look into: if we should update this with minting/burning for Proof of Colleteral (?)
    mapping(address asset => uint256 balance) public s_totalAssetBalances;
    mapping(address user => uint256 sUSDMinted) s_sUSDBalanceUser;
    mapping(address user => mapping(address asset => uint256 userBalance)) public s_userBalances;
    mapping(address user => mapping(address asset => uint256 liability)) public s_userLiabilities;


    ////////////////////////////////////////////////////////////////////////////////
    ///////////////////////////// Reusable modifiers ///////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////
    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert NotOwner(msg.sender);
        }
        _;
    }

    modifier nonReentrant() {
        assembly {
            if tload(0) { revert(0, 0) }
            tstore(0, 1)
        }
        _;
        assembly {
            tstore(0, 0)
        }
    }

    ////////////////////////////////////////////////////////////////////////////////
    ///////////////////////// Internal Helper Functions ////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////
    function _updateBalances(address _user, address _asset, int256 _amount) internal {
        if (_amount < 0) {
            uint256 amount = uint256(-_amount);
            s_totalAssetBalances[_asset] -= amount;
            s_userBalances[_user][_asset] -= amount;
        } else {
            uint256 amount = uint256(_amount);
            s_totalAssetBalances[_asset] += amount;
            s_userBalances[_user][_asset] += amount;
        }
    }
}
