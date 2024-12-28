//SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import {MockOracle} from "./mocks/MockOracle.sol";

/**
 * @title Global State Provider
 * @author 0xTimefliez https://github.com/timefliez1210
 * @notice This abstract inherits into Stable.sol, StableLending.sol and DynamicLending.sol
 * to provide a global accessable state between those modules.
 */
abstract contract Utils is MockOracle {
    struct LendingPosition {
        mapping(address asset => uint256 collateral) s_collateral;
        bool isStableLending;
        uint256 sUsdMinted;
        uint256 interestRate;
        uint256 lastInterestUpdate;
    }

    error NotOwner(address);

    address public constant ETHER = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    uint256 public constant MIN_DEPOSIT_ETH = 1e6;
    address owner;

    address[] public allowlist;
    mapping(address user => LendingPosition) public s_lendingPositions;
    mapping(address asset => bool isAllowed) public s_whitelist;
    mapping(address asset => uint256 balance) public s_totalAssetBalances;
    mapping(address user => mapping(address asset => uint256 userBalance)) public s_userBalances;

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
