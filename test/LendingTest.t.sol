//SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import {BaseTest} from "./utils/BaseTest.t.sol";
import {console} from "forge-std/Test.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

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
        console.log(stable._getUSDAssetValue(address(weth)));
        weth.mint(users[1], 3e18);
        wbtc.mint(users[1], 3e18);
        vm.startPrank(users[1]);
        stable.mintStable(amountToDeposit, amountColleteral, colleterals);
        console.log(sUSD.balanceOf(users[1]));
        stable.mintStable(0, amountColleteral, newColleteral);
        stable.unlockColleteral(address(wbtc), 1e18);
        vm.stopPrank();
    }

    // function test_fuzz_unlockColleteralFail(uint256 amountToDeposit, uint256 amountToUnlock) public {
    //     vm.assume(amountToDeposit > 1e18);
    //     vm.assume(amountToDeposit <= 10.156e21);
    //     vm.assume(amountToUnlock > amountToDeposit);
    //     vm.assume(amountToUnlock <= 10.156e21);
    //     uint256[] memory amountColleteral = new uint256[](2);
    //     address[] memory newColleteral = new address[](1);
    //     newColleteral[0] = address(weth);
    //     amountColleteral[0] = 2e18;
    //     amountColleteral[1] = 1e18;
    //     _userDeposits();
    //     weth.mint(users[1], 3e18);
    //     wbtc.mint(users[1], 3e18);
    //     vm.startPrank(users[1]);
    //     stable.mintStable(amountToDeposit, amountColleteral, colleterals);
    //     console.log(sUSD.balanceOf(users[1]));
    //     uint256 healthFactor = stable.getHealthFactor(users[1]);
    //     console.log(healthFactor);
    //     vm.expectRevert();
    //     stable.unlockColleteral(address(wbtc), amountToUnlock);
    //     healthFactor = stable.getHealthFactor(users[1]);
    //     console.log(healthFactor);
    //     vm.stopPrank();
    // }

    function test_fuzz_repayStableIncreasesHealthFactor(uint256 amountToDeposit) public {
        vm.assume(amountToDeposit > 1e18);
        vm.assume(amountToDeposit <= 10.156e21);
        uint256[] memory amountColleteral = new uint256[](2);
        address[] memory newColleteral = new address[](1);
        newColleteral[0] = address(weth);
        amountColleteral[0] = 2e18;
        amountColleteral[1] = 1e18;
        _userDeposits();
        vm.startPrank(users[1]);
        stable.mintStable(amountToDeposit, amountColleteral, colleterals);
        uint256 heathFactorBefore = stable.getHealthFactor(users[1]);
        console.log(heathFactorBefore);
        sUSD.approve(address(stable), type(uint256).max);
        stable.repayStable(sUSD.balanceOf(users[1]) / 2);
        uint256 heathFactorAfter = stable.getHealthFactor(users[1]);
        console.log(heathFactorAfter);
        vm.stopPrank();
        assert(heathFactorAfter > heathFactorBefore);
    }

    // function test_fuzz_liquidateUserSuccess() public {
    //     vm.warp(1);
    //     address liquidator = makeAddr("liquidator");
    //     uint256[] memory amountColleteral = new uint256[](2);
    //     address[] memory newColleteral = new address[](1);
    //     newColleteral[0] = address(weth);
    //     amountColleteral[0] = 2e18;
    //     amountColleteral[1] = 1e18;
    //     _userDeposits();
    //     vm.startPrank(users[1]);
    //     stable.mintStable(1e21, amountColleteral, colleterals);
    //     vm.stopPrank();
    //     weth.mint(liquidator, 20e18);
    //     wbtc.mint(liquidator, 20e18);
    //     vm.startPrank(liquidator);
    //     weth.approve(address(stable), 20e18);
    //     wbtc.approve(address(stable), 20e18);
    //     stable.deposit(address(weth), 20e18);
    //     stable.deposit(address(wbtc), 20e18);
    //     uint256[] memory amountColleteralLiquidator = new uint256[](2);
    //     amountColleteralLiquidator[0] = 20e18;
    //     amountColleteralLiquidator[1] = 20e18;
    //     stable.mintStable(20e18, amountColleteralLiquidator, colleterals);
    //     sUSD.approve(address(stable), type(uint256).max);
    //     oracle.setPriceWeth(2000);
    //     console.log(stable._getUSDAssetValue(address(weth)));
    //     bool isLiquidatable = stable.isLiquidatable(users[1]);
    //     assertEq(isLiquidatable, true);
    //     stable.liquidatePosition(users[1]);
    //     vm.stopPrank();
    // }

    function test_fuzz_liquidateUserFail() public {
        vm.warp(1);
        address liquidator = makeAddr("liquidator");
        uint256[] memory amountColleteral = new uint256[](2);
        address[] memory newColleteral = new address[](1);
        newColleteral[0] = address(weth);
        amountColleteral[0] = 2e18;
        amountColleteral[1] = 1e18;
        _userDeposits();
        vm.startPrank(users[1]);
        stable.mintStable(1e21, amountColleteral, colleterals);
        vm.stopPrank();
        weth.mint(liquidator, 20e18);
        wbtc.mint(liquidator, 20e18);
        vm.startPrank(liquidator);
        weth.approve(address(stable), 20e18);
        wbtc.approve(address(stable), 20e18);
        stable.deposit(address(weth), 20e18);
        stable.deposit(address(wbtc), 20e18);
        uint256[] memory amountColleteralLiquidator = new uint256[](2);
        amountColleteralLiquidator[0] = 20e18;
        amountColleteralLiquidator[1] = 20e18;
        stable.mintStable(20e18, amountColleteralLiquidator, colleterals);
        sUSD.approve(address(stable), type(uint256).max);
        bool isLiquidatable = stable.isLiquidatable(users[1]);
        assertEq(isLiquidatable, false);
        vm.expectRevert();
        stable.liquidatePosition(users[1]);
        vm.stopPrank();
    }

    function test_fuzz_donateSuccessAndIncreaseHealthFactor() public {
    }

    function test_donateFails() public {
        uint256[] memory amountColleteral = new uint256[](2);
        amountColleteral[0] = 2e18;
        amountColleteral[1] = 1e18;
        _userDeposits();
        vm.startPrank(users[1]);
        stable.mintStable(1e21, amountColleteral, colleterals);
        sUSD.approve(address(stable), type(uint256).max);
        console.log(stable.getStableLendingHealthFactor());
        uint256 amountToDonate = sUSD.balanceOf(users[1]);
        vm.expectRevert();
        stable.donate(amountToDonate);
        console.log(stable.getStableLendingHealthFactor());
        vm.stopPrank();
    }

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
