//SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import {Utils} from "../Utils.sol";
import {StableUSD} from "../tokens/StableUSD.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";


// @todo gotta implement interest, and liquidation fees
// @todo find better ways as thos mucho mucho loops
abstract contract Lending is Utils {
    using SafeERC20 for IERC20;
    error NotSupportedAsset(address);
    error ToHighAsk(uint256);
    error CanNotMintZero();
    error CanNotBurnZero();
    error CanNotBurnMoreThanBalance(uint256);
    error UserPositionHealthy(uint256);
    
    uint256 private constant PRECISION_NOMINATOR = 8000;
    uint256 private constant PRECISION_DENOMINATOR = 100;
    uint256 private constant LIQUIDATION_THRESHOLD = 95;

    StableUSD susd;

    constructor() {
        susd = new StableUSD(address(this));
    }

    function mintStable(uint256 _amount, address[] calldata _colleteral) external {
        if(_amount == 0) {
            revert CanNotMintZero();
        }
        uint256 totalUsdValueUser = _getAccumulatedAssetValue(_colleteral);
        uint256 healthFactor = _getHealthFactor(totalUsdValueUser, _amount);
        if(healthFactor < 100) {
            revert ToHighAsk(_amount);
        }
        _shiftColleteralAssets(_colleteral);
        s_sUSDBalanceUser[msg.sender] += _amount;
        susd.mint(msg.sender, _amount);
    }

    //@todo find a better way to track user locked colleteral to unlock assets (?)
    function repayStable(uint256 _amount) external {
        if(_amount == 0) {
            revert CanNotBurnZero();
        }
        if(_amount > s_sUSDBalanceUser[msg.sender]) {
            revert CanNotBurnMoreThanBalance(s_sUSDBalanceUser[msg.sender]);
        }
        s_sUSDBalanceUser[msg.sender] -= _amount;
        IERC20(susd).safeTransferFrom(msg.sender, address(this), _amount);
        susd.burn(_amount);
    }

    // @todo this liquidation logic sucks smh, gotta revisit that
    function liquidatePosition(address _user) external nonReentrant {
        uint256 totalUsdValueUser = _getUserPositionsValue(_user);
        uint256 sUsdMintedUser = s_sUSDBalanceUser[_user];
        uint256 healthFactor = _getHealthFactor(totalUsdValueUser, sUsdMintedUser);
        if(healthFactor <= LIQUIDATION_THRESHOLD) {
            // Effects
            s_sUSDBalanceUser[_user] = 0;
            // Interactions
            IERC20(susd).safeTransferFrom(msg.sender, address(this), sUsdMintedUser);
            for(uint256 i; i < allowlist.length; i++){
                //Effects
                uint256 amountToSend = s_userLiabilities[_user][allowlist[i]];
                s_userLiabilities[_user][allowlist[i]] = 0;
                //Interactions
                if(amountToSend > 0) {  
                    IERC20(allowlist[i]).safeTransfer(msg.sender, amountToSend);
                }
            }
            susd.burn(sUsdMintedUser);
        } else {
            revert UserPositionHealthy(healthFactor);
        }
    }

    function _getUserPositionsValue(address _user) internal view returns(uint256) {
        uint256 totalUsdValueUser;
        for(uint256 i; i < allowlist.length; i++) {
            uint256 tokenCount =  s_userLiabilities[_user][allowlist[i]];
            uint256 usdValueToken = _getUSDAssetValue(allowlist[i]);
            totalUsdValueUser += tokenCount * usdValueToken;
        }
        return totalUsdValueUser;
    }

    function _getAccumulatedAssetValue(address[] calldata _colleteral) internal view returns(uint256) {
        uint256 totalUsdValueUser;
        uint256 usdValue;
        for(uint256 i = 0; i < _colleteral.length; i++) {
            usdValue = _getUSDAssetValue(_colleteral[i]);
            uint256 amountColleteral = s_userBalances[msg.sender][_colleteral[i]];
            totalUsdValueUser += usdValue * amountColleteral;
        }
        return totalUsdValueUser;
    }

    function _getUSDAssetValue(address _asset) internal view returns(uint256) {
        uint256 usdValue;
        if(s_whitelist[_asset]){
            usdValue = getPrice(_asset);
                
        } else {
            revert NotSupportedAsset(_asset);
        }
        return usdValue;
    }

    function _getHealthFactor(uint256 _usdValueUser, uint256 _amountMinted) internal pure returns(uint256) {
        uint256 healthFactor = (PRECISION_NOMINATOR * _usdValueUser) / (PRECISION_DENOMINATOR * _amountMinted);
        return healthFactor;
    }

    function _shiftColleteralAssets(address[] calldata _colleteral) internal {
        for(uint256 i = 0; i < _colleteral.length; i++) {
            address asset = _colleteral[i];
            uint256 liabilities = s_userBalances[msg.sender][asset];
            s_userBalances[msg.sender][asset] = 0;
            s_userLiabilities[msg.sender][asset] = liabilities;
        }
    }
}
