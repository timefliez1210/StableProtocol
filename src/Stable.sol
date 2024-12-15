//SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import {Utils} from "./Utils.sol";
import {StableLending} from "./modules/StableLending.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";

/**
 * @title Decentralized Stablecoin with mixed over-collateralisation
 * @author 0xTimefliez https://github.com/timefliez1210
 * @notice
 */
// @todo currently user cant withdraw posted colleteral at all, after fixing those nasty loops
// add a healthfactor check in withdraw to allow withdrawing in case of overcolleteralization
contract Stable is Utils, StableLending {
    using SafeERC20 for IERC20;

    error NotWhitelistedAsset(address);
    error BelowMinimumDeposit();
    error AmountExceedsUserBalance(uint256, uint256);
    error StopDoingWeirdStuff();

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
        if (!s_whitelist[_asset]) {
            revert NotWhitelistedAsset(_asset);
        }
        if (_amount == 0) {
            if (msg.value < MIN_DEPOSIT_ETH) {
                revert BelowMinimumDeposit();
            } else {
                _updateBalances(msg.sender, _asset, int256(msg.value));
            }
        } else {
            IERC20(_asset).safeTransferFrom(msg.sender, address(this), _amount);
            _updateBalances(msg.sender, _asset, int256(_amount));
        }
    }

    function withdraw(address _asset, uint256 _amount) external nonReentrant {
        // Checks
        if (_amount > s_userBalances[msg.sender][_asset]) {
            revert AmountExceedsUserBalance(_amount, s_userBalances[msg.sender][_asset]);
        }
        if (_asset == ETHER) {
            // Effects
            int256 amount = -int256(_amount);
            _updateBalances(msg.sender, _asset, amount);
            address payable to = payable(msg.sender);
            require(to != address(0), "conversion went wrong!");
            // Interactions
            (bool success,) = to.call{value: _amount}("");
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
        allowlist.push(_token);
    }

    ////////////////////////////////////////////////////////////////////////////////
    ///////////////////////// Public Getter Functions //////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////
    function isWhitelisted(address _token) public view returns (bool) {
        return s_whitelist[_token];
    }

    function getTotalBalance(address _asset) public view returns (uint256) {
        return s_totalAssetBalances[_asset];
    }

    function getUserBalance(address _user, address _asset) public view returns (uint256) {
        return s_userBalances[_user][_asset];
    }
}
