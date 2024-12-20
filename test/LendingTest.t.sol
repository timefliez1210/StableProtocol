//SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import {BaseTest} from "./utils/BaseTest.t.sol";
import {console} from "forge-std/Test.sol";

contract LendingTest is BaseTest {
    address[] colleterals;

    function test_fuzz_mintStableSuccess(uint256 amount) public {
        vm.assume(amount > 0);
        vm.assume(amount <= 10.156e21);
        uint256[] memory amountColleteral = new uint256[](2);
        amountColleteral[0] = 2e18;
        amountColleteral[1] = 1e18;
        _userDeposits();
        vm.startPrank(users[1]);
        stable.mintStable(amount, amountColleteral, colleterals);
        vm.stopPrank();
    }

    function test_fuzz_mintStableFailToHighAsk(uint256 amount) public {
        vm.assume(amount >= 11e21);
        uint256[] memory amountColleteral = new uint256[](2);
        amountColleteral[0] = 2e18;
        amountColleteral[1] = 1e18;
        _userDeposits();
        vm.startPrank(users[1]);
        vm.expectRevert();
        stable.mintStable(amount, amountColleteral, colleterals);
        vm.stopPrank();
    }

    function test_fuzz_unlockColleteralSuccess(uint256 amountToDeposit, uint256 amountToUnlock) public {
        vm.assume(amountToDeposit > 1e18);
        vm.assume(amountToDeposit <= 10.156e21);
        vm.assume(amountToUnlock <= 10.156e21);
        uint256[] memory amountColleteral = new uint256[](2);
        address[] memory newColleteral = new address[](1);
        newColleteral[0] = address(weth);
        amountColleteral[0] = 2e18;
        amountColleteral[1] = 1e18;
        _userDeposits();
        weth.mint(users[1], 3e18);
        wbtc.mint(users[1], 3e18);
        vm.startPrank(users[1]);
        stable.mintStable(amountToDeposit, amountColleteral, colleterals);
        console.log(sUSD.balanceOf(users[1]));
        stable.mintStable(0, amountColleteral, newColleteral);
        stable.unlockColleteral(address(wbtc), 1e18);
        vm.stopPrank();
    }

    function test_fuzz_unlockColleteralFail(uint256 amountToDeposit, uint256 amountToUnlock) public {
        vm.assume(amountToDeposit > 1e18);
        vm.assume(amountToDeposit <= 10.156e21);
        vm.assume(amountToUnlock > amountToDeposit);
        vm.assume(amountToUnlock <= 10.156e21);
        uint256[] memory amountColleteral = new uint256[](2);
        address[] memory newColleteral = new address[](1);
        newColleteral[0] = address(weth);
        amountColleteral[0] = 2e18;
        amountColleteral[1] = 1e18;
        _userDeposits();
        weth.mint(users[1], 3e18);
        wbtc.mint(users[1], 3e18);
        vm.startPrank(users[1]);
        stable.mintStable(amountToDeposit, amountColleteral, colleterals);
        console.log(sUSD.balanceOf(users[1]));
        uint256 healthFactor = stable.getHealthFactor(users[1]);
        console.log(healthFactor);
        vm.expectRevert();
        stable.unlockColleteral(address(wbtc), amountToUnlock);
        healthFactor = stable.getHealthFactor(users[1]);
        console.log(healthFactor);
        vm.stopPrank();
    }

    function test_fuzz_repayStableIncreasesHealthFactor() public {}

    function test_fuzz_liquidateUserSuccess() public {}

    function test_fuzz_liquidateUserFail() public {}

    function test_fuzz_donateSuccessAndIncreaseHealthFactor() public {}

    function test_donateFails() public {}

    function _userDeposits() public {
        whitelistTokens();
        colleterals.push(address(weth));
        colleterals.push(address(wbtc));
        for (uint256 i = 1; i < users.length; i++) {
            vm.startPrank(users[i]);
            stable.deposit(address(weth), 8e18);
            stable.deposit(address(wbtc), 8e18);
            vm.stopPrank();
        }
    }
}
