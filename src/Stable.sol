//SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import {Utils} from "./Utils.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title Decentralized Stablecoin with mixed over-collateralisation 
 * @author 0xTimefliez https://github.com/timefliez1210
 * @notice 
 */
contract Stable is Utils {
    using SafeERC20 for IERC20;
    error NotWhitelistedAsset(address);
    error BelowMinimumDeposit();

    mapping(address asset => bool isAllowed) public s_whitelist;
    mapping(address asset => uint256 balance) public s_totalAssetBalances;
    mapping(address user => mapping(address asset => uint256 userBalance)) public s_userBalances;


    constructor() {
        owner = msg.sender;
        s_whitelist[0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE] = true;
    }

    /**
     * @dev deposit functionality for all whitelisted ERC20s and Ether, also entrypoint for all accounting
     * @param _asset address of the asset to deposit, user 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE for native Ether
     * @param _amount amount of an asset to deposit, use 0 for depositing ether
     */
    function deposit(address _asset, uint256 _amount) external payable {
        if(!s_whitelist[_asset]) {
            revert NotWhitelistedAsset(_asset);
        }
        if(_amount == 0) {
            if(msg.value < MIN_DEPOSIT_ETH) {
                revert BelowMinimumDeposit();
            } else {
                _updateBalances(msg.sender, _asset, msg.value);
            }
        } else {
            IERC20(_asset).safeTransferFrom(msg.sender, address(this), _amount);
            _updateBalances(msg.sender, _asset, _amount);
        }
    }

    function whitelistTokens(address _token) external onlyOwner {
        s_whitelist[_token] = true;
    }

    function isWhitelisted(address _token) external view returns(bool) {
        return s_whitelist[_token];
    }
    
    function _updateBalances(address _user, address _asset, uint256 _amount) internal {
        s_totalAssetBalances[_asset] += _amount;
        s_userBalances[_user][_asset] += _amount;
    }
}