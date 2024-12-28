//SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import {BaseTest} from "../utils/BaseTest.t.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Handler is BaseTest {

    uint256 public balanceBeforeStable;
    uint256 public balanceBeforeUser;
    uint256 public balanceAfterStable;
    uint256 public balanceAfterUser;

    constructor() {
        setUp();
        whitelistTokens();
    }

    function testDeposit(uint256 indexAddress_, uint256 amount_, uint256 indexUser_) public {
        indexUser_ = bound(indexUser_, 1, 5);
        indexAddress_ = bound(indexAddress_, 0, 2);
        amount_ = bound(amount_, 0, 10e18);
        address asset_ = allowlist[indexAddress_];
        balanceBeforeStable = IERC20(asset_).balanceOf(address(stable));
        balanceBeforeUser = s_userBalances[users[indexUser_]][asset_];
        vm.prank(users[indexUser_]);
        stable.deposit(asset_, amount_);
        balanceAfterStable = IERC20(asset_).balanceOf(address(stable));
        balanceAfterUser = s_userBalances[users[indexUser_]][asset_];
    }
}