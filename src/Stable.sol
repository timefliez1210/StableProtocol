//SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import {Utils} from "./Utils.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";

/**
 * @title Decentralized Stablecoin with mixed over-collateralisation 
 * @author 0xTimefliez https://github.com/timefliez1210
 * @notice 
 */
contract Stable is Utils {
    using SafeERC20 for IERC20;
    error NotWhitelistedAsset(address);
    error BelowMinimumDeposit();
    error AmountExceedsUserBalance(uint256, uint256);
    error StopDoingWeirdStuff();

    mapping(address asset => bool isAllowed) public s_whitelist;
    mapping(address asset => uint256 balance) public s_totalAssetBalances;
    mapping(address user => mapping(address asset => uint256 userBalance)) public s_userBalances;


    constructor() {
        owner = msg.sender;
        s_whitelist[0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE] = true;
    }

    ////////////////////////////////////////////////////////////////////////////////
    /////////////////////// External User-Facing Functions /////////////////////////
    ////////////////////////////////////////////////////////////////////////////////
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
                _updateBalances(msg.sender, _asset, int256(msg.value));
            }
        } else {
            IERC20(_asset).safeTransferFrom(msg.sender, address(this), _amount);
            _updateBalances(msg.sender, _asset, int256(_amount));
        }
    }

    function withdraw(address _asset, uint _amount) external nonReentrant {
        /*
         * @Todo if theres colleteral attached we need to check Health factor etc.
         */
        // Checks
        if(_amount > s_userBalances[msg.sender][_asset]) {
            revert AmountExceedsUserBalance(_amount, s_userBalances[msg.sender][_asset]);
        }
        if(_asset == ETHER) {
            // Effects
            int256 amount = -int256(_amount); 
            _updateBalances(msg.sender, _asset, amount);
            address payable to = payable(msg.sender);
            require(to != address(0), "conversion went wrong!");
            // Interactions
            (bool success, ) = to.call{value: _amount}("");
            require(success, "transfer failed!");
        } else {
            // Effects
            int256 amount = -int256(_amount); 
            _updateBalances(msg.sender, _asset, amount);
            // Interaction
            IERC20(_asset).safeTransfer(msg.sender, _amount);
        } 
    }

    ////////////////////////////////////////////////////////////////////////////////
    /////////////////////// External Priviledged Functions /////////////////////////
    ////////////////////////////////////////////////////////////////////////////////
    function whitelistTokens(address _token) external onlyOwner {
        s_whitelist[_token] = true;
    }

    ////////////////////////////////////////////////////////////////////////////////
    ///////////////////////// Public Getter Functions //////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////
    function isWhitelisted(address _token) public view returns(bool) {
        return s_whitelist[_token];
    }
    
    function getTotalBalance(address _asset) public view returns(uint256) {
        return s_totalAssetBalances[_asset];
    }

    function getUserBalance(address _user, address _asset) public view returns (uint256) {
        return s_userBalances[_user][_asset];
    }

    ////////////////////////////////////////////////////////////////////////////////
    ///////////////////////// Internal Helper Functions ////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////
    function _updateBalances(address _user, address _asset, int256 _amount) internal {
        if(_amount < 0) {
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