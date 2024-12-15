//SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import {Utils} from "../Utils.sol";
import {StableUSD} from "../tokens/StableUSD.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// @todo gotta implement interest, and liquidation fees
// @todo find better ways as thos mucho mucho loops
/**
 * @title StableLending
 * @author 0xTimefliez https://github.com/timefliez1210
 * @notice This part of the code only handles minting and burning of the issued stablecoin (loans, repay and liquidations)
 * and intentionally does not support cascading liquidations. Whitelisted assets are assumed to only be
 * major currencies (WETH, WBTC, etc.). We offer a high LTV on these assets but enforce extremly strict liquidation.
 * Multi-Asset Colleteralization IS supported, which allows to shift the colleteral from e.g. WETH to WBTC or higher the colleteraliztion
 * in other supported assets.
 * @dev this contract never directly transfers funds out (only mints!) withdrawals are only supported though Stable.sol (except liquidations)
 */
abstract contract StableLending is Utils {
    using SafeERC20 for IERC20;

    ////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////// Custom Errors //////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////
    error NotSupportedAsset(address);
    error TooHighAsk(uint256);
    error CanNotMintZero();
    error CanNotBurnZero();
    error CanNotBurnMoreThanBalance(uint256);
    error UserPositionHealthy(uint256);
    error CanNotUnlockZero();
    error AmountExceedsLiability(address, uint256, uint256);

    ////////////////////////////////////////////////////////////////////////////////
    //////////////////////// Constants & Immutables ////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////
    uint256 private constant PRECISION_NOMINATOR = 8000;
    uint256 private constant PRECISION_DENOMINATOR = 100;
    uint256 private constant LIQUIDATION_THRESHOLD = 95;
    StableUSD immutable i_susd;

    ////////////////////////////////////////////////////////////////////////////////
    //////////////////////// Mutable State Vaiables ////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////

    mapping(address user => address[] depositedColleteral) s_depositedColleteralsByUser;
    mapping(address asset => uint256 amount) s_backingAssets;

    constructor() {
        i_susd = new StableUSD(address(this));
    }

    ////////////////////////////////////////////////////////////////////////////////
    /////////////////////// External User-Facing Functions /////////////////////////
    ////////////////////////////////////////////////////////////////////////////////

    //////////////////////////////
    //// State Changing Functions
    //////////////////////////////
    // @todo maybe refactor this so the user does not have to deposit 100% of asset colleteral
    function mintStable(uint256 _amount, address[] calldata _colleteral) external {
        if (_amount == 0) {
            revert CanNotMintZero();
        }
        uint256 totalUsdValueUser = _getAccumulatedAssetValue(_colleteral);
        uint256 healthFactor = _getHealthFactor(totalUsdValueUser, _amount);
        if (healthFactor < 100) {
            revert TooHighAsk(_amount);
        }
        for (uint256 i; i < _colleteral.length; i++) {
            s_backingAssets[_colleteral[i]] += s_userBalances[msg.sender][_colleteral[i]];
        }
        _shiftColleteralAssets(_colleteral);
        s_sUSDBalanceUser[msg.sender] += _amount;
        i_susd.mint(msg.sender, _amount);
    }

    // @todo find a better way to track user locked colleteral to unlock assets (?)
    function repayStable(uint256 _amount) external {
        if (_amount == 0) {
            revert CanNotBurnZero();
        }
        if (_amount > s_sUSDBalanceUser[msg.sender]) {
            revert CanNotBurnMoreThanBalance(s_sUSDBalanceUser[msg.sender]);
        }
        s_sUSDBalanceUser[msg.sender] -= _amount;
        IERC20(i_susd).safeTransferFrom(msg.sender, address(this), _amount);
        i_susd.burn(_amount);
    }

    function unlockColleteral(address _asset, uint256 _amount) external nonReentrant {
        if (_amount == 0) {
            revert CanNotUnlockZero();
        }
        if (_amount > s_userLiabilities[msg.sender][_asset]) {
            revert AmountExceedsLiability(_asset, s_userLiabilities[msg.sender][_asset], _amount);
        }
        uint256 usdAssetValue = _getUSDAssetValue(_asset);
        uint256 usdValueToWithdraw = _amount * usdAssetValue;
        address[] memory assets = s_depositedColleteralsByUser[msg.sender];
        uint256 totalUsdValue = _getAccumulatedAssetValue(assets);
        uint256 potentialUsdValue = totalUsdValue - usdValueToWithdraw;
        uint256 healthFactor = _getHealthFactor(potentialUsdValue, s_sUSDBalanceUser[msg.sender]);
        if (healthFactor > 100) {
            // Effects
            s_backingAssets[_asset] -= _amount;
            s_userLiabilities[msg.sender][_asset] -= _amount;
            s_userBalances[msg.sender][_asset] += _amount;
        } else {
            revert TooHighAsk(_amount);
        }
    }

    // @todo this liquidation logic sucks smh, gotta revisit that
    function liquidatePosition(address _user) external nonReentrant {
        uint256 totalUsdValueUser = _getUserPositionsValue(_user);
        uint256 sUsdMintedUser = s_sUSDBalanceUser[_user];
        uint256 healthFactor = _getHealthFactor(totalUsdValueUser, sUsdMintedUser);
        if (healthFactor <= LIQUIDATION_THRESHOLD) {
            // Effects
            s_sUSDBalanceUser[_user] = 0;
            // Interactions
            IERC20(i_susd).safeTransferFrom(msg.sender, address(this), sUsdMintedUser);
            for (uint256 i; i < s_depositedColleteralsByUser[_user].length; i++) {
                //Effects
                uint256 amountToSend = s_userLiabilities[_user][s_depositedColleteralsByUser[_user][i]];
                s_userLiabilities[_user][s_depositedColleteralsByUser[_user][i]] = 0;
                //Interactions
                if (amountToSend > 0) {
                    if (s_depositedColleteralsByUser[_user][i] == ETHER) {
                        s_backingAssets[ETHER] -= s_userLiabilities[_user][s_depositedColleteralsByUser[_user][i]];
                        (bool success,) = payable(msg.sender).call{value: amountToSend}("");
                        require(success, "Failed to send ether");
                    } else {
                        s_backingAssets[ETHER] -= s_userLiabilities[_user][s_depositedColleteralsByUser[_user][i]];
                        IERC20(s_depositedColleteralsByUser[_user][i]).safeTransfer(msg.sender, amountToSend);
                    }
                }
            }
            i_susd.burn(sUsdMintedUser);
        } else {
            revert UserPositionHealthy(healthFactor);
        }
    }

    //////////////////////////////
    //// View Functions
    //////////////////////////////
    function isLiquidatable(address _user) external view returns (bool) {
        uint256 userUsdValue = _getUserPositionsValue(_user);
        uint256 healthFactor = _getHealthFactor(userUsdValue, s_sUSDBalanceUser[_user]);
        if (healthFactor > LIQUIDATION_THRESHOLD) {
            return false;
        } else {
            return true;
        }
    }

    function getStableLendingHealthFactor() external view returns (uint256) {
        uint256 totalUsdValue;
        for (uint256 i; i < allowlist.length; i++) {
            address asset = allowlist[i];
            uint256 totalAmountAsset = s_backingAssets[asset];
            uint256 usdValueAsset = _getUSDAssetValue(asset);
            totalUsdValue += totalAmountAsset * usdValueAsset;
        }
        uint256 totalSUSDMinted = i_susd.totalSupply();
        uint256 healthFactor = _getHealthFactor(totalUsdValue, totalSUSDMinted);
        return healthFactor;
    }

    ////////////////////////////////////////////////////////////////////////////////
    ///////////////////////// Internal Helper Functions ////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////
    function _getUserPositionsValue(address _user) internal view returns (uint256) {
        uint256 totalUsdValueUser;
        for (uint256 i; i < s_depositedColleteralsByUser[_user].length; i++) {
            uint256 tokenCount = s_userLiabilities[_user][s_depositedColleteralsByUser[_user][i]];
            uint256 usdValueToken = _getUSDAssetValue(s_depositedColleteralsByUser[_user][i]);
            totalUsdValueUser += tokenCount * usdValueToken;
        }
        return totalUsdValueUser;
    }

    function _getAccumulatedAssetValue(address[] memory _colleteral) internal view returns (uint256) {
        uint256 totalUsdValueUser;
        uint256 usdValue;
        for (uint256 i = 0; i < _colleteral.length; i++) {
            usdValue = _getUSDAssetValue(_colleteral[i]);
            uint256 amountColleteral = s_userBalances[msg.sender][_colleteral[i]];
            totalUsdValueUser += usdValue * amountColleteral;
        }
        return totalUsdValueUser;
    }

    function _getUSDAssetValue(address _asset) internal view returns (uint256) {
        uint256 usdValue;
        if (s_whitelist[_asset]) {
            usdValue = getPrice(_asset);
        } else {
            revert NotSupportedAsset(_asset);
        }
        return usdValue;
    }

    function _getHealthFactor(uint256 _usdValueUser, uint256 _amountMinted) internal pure returns (uint256) {
        uint256 healthFactor = (PRECISION_NOMINATOR * _usdValueUser) / (PRECISION_DENOMINATOR * _amountMinted);
        return healthFactor;
    }

    function _shiftColleteralAssets(address[] calldata _colleteral) internal {
        for (uint256 i = 0; i < _colleteral.length; i++) {
            address asset = _colleteral[i];
            uint256 liabilities = s_userBalances[msg.sender][asset];
            s_depositedColleteralsByUser[msg.sender].push(_colleteral[i]);
            s_userBalances[msg.sender][asset] = 0;
            s_userLiabilities[msg.sender][asset] = liabilities;
        }
    }
}
