//SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import {BaseTest} from "./utils/BaseTest.t.sol";

contract LendingTest is BaseTest {
    address[] colleterals;

    function test_fuzz_mintStableSuccess(uint256 amount) public {
        vm.assume(amount > 0);
        vm.assume(amount <= 10.156e21);
        _userDeposits();
        vm.startPrank(users[1]);
        stable.mintStable(amount, colleterals);
        vm.stopPrank();
    }

    function test_fuzz_mintStableFailToHighAsk(uint256 amount) public {
        vm.assume(amount >= 10.156e21);
        _userDeposits();
        vm.startPrank(users[1]);
        vm.expectRevert();
        stable.mintStable(amount, colleterals);
        vm.stopPrank();
    }

    function _userDeposits() public {
        whitelistTokens();
        colleterals.push(address(weth));
        colleterals.push(address(wbtc));
        for (uint256 i = 1; i < users.length; i++) {
            vm.startPrank(users[i]);
            stable.deposit(address(weth), 2e18);
            stable.deposit(address(wbtc), 1e18);
            vm.stopPrank();
        }
    }
}
