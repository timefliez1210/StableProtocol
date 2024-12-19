//SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import {Utils} from "../Utils.sol";
import {StableUSD} from "../tokens/StableUSD.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// @todo gotta implement interest and liquidation fees
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

    /**
     * @dev Invariant: a user should never be able to mint below a healthFactor of 100
     * @notice use this function to _mint sUSD or to increase your colleteralization/increase your Health Factor
     * @param _amountToMint amount of sUSD the user wants to mint
     * @param _amountColleteral array of colleteral amounts to move from balance -> liabilities backing the position
     * @param _colleteral array of colleteral address to move from balance -> liabilities backing the position
     * Important: the order of the colleteral and amounts must match => colleteral[0] => amountColleteral[0]
     */
    function mintStable(uint256 _amountToMint, uint256[] calldata _amountColleteral, address[] calldata _colleteral)
        external
    {
        uint256 totalUsdValueUser;
        for (uint256 i; i < _colleteral.length; i++) {
            uint256 usdValueAsset = _getUSDAssetValue(_colleteral[i]);
            // @todo add this into the struct and finish refactor
            s_depositedColleteralsByUser[msg.sender].push(_colleteral[i]);
            totalUsdValueUser += _amountColleteral[i] * usdValueAsset;
            s_lendingPositions[msg.sender].s_collateral[_colleteral[i]] += _amountColleteral[i];
            s_userBalances[msg.sender][_colleteral[i]] -= _amountColleteral[i];
        }
        uint256 healthFactor = _getHealthFactor(totalUsdValueUser, _amountToMint);
        if (healthFactor < 100) {
            revert TooHighAsk(_amountToMint);
        }

        s_lendingPositions[msg.sender].isStableLending = true;
        s_lendingPositions[msg.sender].sUsdMinted += _amountToMint;
        i_susd.mint(msg.sender, _amountToMint);
    }

    /**
     * @dev handles the burn mechanism
     * @notice use this function to increase your health factor and unwind positions.
     * @param _amount amount of sUSD to burn
     */
    function repayStable(uint256 _amount) external {
        if (_amount == 0) {
            revert CanNotBurnZero();
        }
        if (_amount > s_lendingPositions[msg.sender].sUsdMinted) {
            revert CanNotBurnMoreThanBalance(s_lendingPositions[msg.sender].sUsdMinted);
        }
        s_lendingPositions[msg.sender].sUsdMinted -= _amount;
        IERC20(i_susd).safeTransferFrom(msg.sender, address(this), _amount);
        i_susd.burn(_amount);
    }

    /**
     * @dev critical function, any misbehaviour here would cause protocol insolvency or
     * loss of user funds.
     * @notice call this to unlock assets for withdrawal or other operations.
     * @param _asset address of asset to move back into balance
     * @param _amount amount of an asset to move back into balance
     */
    function unlockColleteral(address _asset, uint256 _amount) external nonReentrant {
        if (_amount == 0) {
            revert CanNotUnlockZero();
        }
        if (_amount > s_lendingPositions[msg.sender].s_collateral[_asset]) {
            revert AmountExceedsLiability(_asset, s_lendingPositions[msg.sender].s_collateral[_asset], _amount);
        }
        uint256 usdAssetValue = _getUSDAssetValue(_asset);
        uint256 usdValueToWithdraw = _amount * usdAssetValue;
        address[] memory assets = s_depositedColleteralsByUser[msg.sender];
        uint256 totalUsdValue = _getAccumulatedAssetValue(assets);
        uint256 potentialUsdValue = totalUsdValue - usdValueToWithdraw;
        uint256 healthFactor = _getHealthFactor(potentialUsdValue, s_lendingPositions[msg.sender].sUsdMinted);
        if (healthFactor > 100) {
            // Effects
            s_backingAssets[_asset] -= _amount;
            s_lendingPositions[msg.sender].s_collateral[_asset] -= _amount;
            s_userBalances[msg.sender][_asset] += _amount;
        } else {
            revert TooHighAsk(_amount);
        }
    }

    /**
     * @dev this function is the bread and butter. For the sake of protocol solvency
     * and peg of sUSD this function must work under all circumstances. Any failure is critical.
     * @notice call this to liquidate users and claim their colleteral minus a protocol fee
     * @param _user user address to liquidate
     */
    function liquidatePosition(address _user) external nonReentrant {
        uint256 totalUsdValueUser = _getUserPositionsValue(_user);
        uint256 sUsdMintedUser = s_lendingPositions[_user].sUsdMinted;
        uint256 healthFactor = _getHealthFactor(totalUsdValueUser, sUsdMintedUser);
        if (healthFactor <= LIQUIDATION_THRESHOLD) {
            s_lendingPositions[_user].sUsdMinted = 0;
            IERC20(i_susd).safeTransferFrom(msg.sender, address(this), sUsdMintedUser);
            for (uint256 i; i < s_depositedColleteralsByUser[_user].length; i++) {
                uint256 amountToSend = s_lendingPositions[_user].s_collateral[s_depositedColleteralsByUser[_user][i]];
                s_lendingPositions[_user].s_collateral[s_depositedColleteralsByUser[_user][i]] = 0;
                if (amountToSend > 0) {
                    if (s_depositedColleteralsByUser[_user][i] == ETHER) {
                        s_backingAssets[ETHER] -=
                            s_lendingPositions[_user].s_collateral[s_depositedColleteralsByUser[_user][i]];
                        (bool success,) = payable(msg.sender).call{value: amountToSend}("");
                        require(success, "Failed to send ether");
                    } else {
                        s_backingAssets[ETHER] -=
                            s_lendingPositions[_user].s_collateral[s_depositedColleteralsByUser[_user][i]];
                        IERC20(s_depositedColleteralsByUser[_user][i]).safeTransfer(msg.sender, amountToSend);
                    }
                }
            }    
        } else {
            revert UserPositionHealthy(healthFactor);
        }
        i_susd.burn(sUsdMintedUser);
    }

    //////////////////////////////
    //// View Functions
    //////////////////////////////

    /**
     * @dev Use this to effectively query possible liquidations.
     * @param _user user address to query for possible Liquidation.
     */
    function isLiquidatable(address _user) external view returns (bool)  {
        uint256 userUsdValue = _getUserPositionsValue(_user);
        uint256 healthFactor = _getHealthFactor(userUsdValue, s_lendingPositions[_user].sUsdMinted);
        if (healthFactor > LIQUIDATION_THRESHOLD) {
            return false;
        } else {
            return true;
        }
    }
    /**
     * @dev returns the Health Factor of StableLending in entirety.
     * Basically a proof of colleteralization.
     */

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
            uint256 tokenCount = s_lendingPositions[_user].s_collateral[s_depositedColleteralsByUser[_user][i]];
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
}
