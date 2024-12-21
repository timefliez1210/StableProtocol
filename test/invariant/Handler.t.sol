//SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import {Stable} from "../../src/Stable.sol";
import {BaseTest} from "../utils/BaseTest.t.sol";

contract Handler is Stable, BaseTest {
    function erc20Workflow(address _user, uint256 _amountToDeposit, uint256 _amountToMint, uint256 _userIndex) public {
        vm.assume(_user != address(0));
        vm.assume(_user != owner);
        _amountToDeposit = bound(_amountToDeposit, 1, 10.156e21);
        // uint256 maxAmountToMint =
        _amountToMint = bound(_amountToMint, 1, 10.156e21);
        _userIndex = bound(_userIndex, 0, 5);
    }

    function _setUp() internal {
        whitelistTokens();
    }
}
