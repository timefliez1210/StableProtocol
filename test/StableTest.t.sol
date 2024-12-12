//SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import {BaseTest} from "./utils/BaseTest.t.sol";

contract StableTest is BaseTest {

    function test_whitelistNotOwner() public {
        vm.startPrank(users[1]);
        vm.expectRevert();
        stable.whitelistTokens(address(weth));
        vm.stopPrank();
    }
    function test_fuzz_depositEtherSuccess(uint256 amount) public {
        vm.assume(amount <= 10e18);
        vm.assume(amount > MIN_DEPOSIT_ETH);
        assertEq(users[1].balance, 10e18);
        assertEq(address(stable).balance, 0);
        vm.startPrank(users[1]);
        (bool success,) = address(stable).call{value: amount}(abi.encodeWithSignature("deposit(address,uint256)", ETHER, 0));
        vm.stopPrank();
        assertEq(users[1].balance, 10e18 - amount);
        assertEq(address(stable).balance, amount);
        assertEq(success, true);
    }

    function test_fuzz_depositEtherBelowMinimum(uint256 amount) public {
        vm.assume(amount < MIN_DEPOSIT_ETH);
        assertEq(users[1].balance, 10e18);
        assertEq(address(stable).balance, 0);
        vm.startPrank(users[1]);
        vm.expectRevert();
        (bool success,) = address(stable).call{value: amount}(abi.encodeWithSignature("deposit(address,uint256)", ETHER, 0));
        vm.stopPrank();
        assertEq(users[1].balance, 10e18);
        assertEq(address(stable).balance, 0);
        assertEq(success, true);
    }

    function test_fuzz_depositERC20Success(uint256 amount) public {
        vm.assume(amount <= 10e18);
        vm.assume(amount > 0);
        whitelistTokens();
        vm.startPrank(users[1]);
        stable.deposit(address(weth), amount);
        stable.deposit(address(wbtc), amount);
        vm.stopPrank();
        assertEq(weth.balanceOf(users[1]), 10e18 - amount);
        assertEq(wbtc.balanceOf(users[1]), 10e18 - amount);
        assertEq(wbtc.balanceOf(address(stable)), amount);
        assertEq(weth.balanceOf(address(stable)), amount);
    }

    function test_depositNotWhitelistedToken() public {
        assertEq(users[1].balance, 10e18);
        assertEq(address(stable).balance, 0);
        vm.startPrank(users[1]);
        vm.expectRevert();
        stable.deposit(address(weth), 5e18);
        vm.stopPrank();
        assertEq(users[1].balance, 10e18);
        assertEq(address(stable).balance, 0);
    }

    function test_depositZeroAmountFail(uint256 amount) public {
        vm.assume(amount <= 10e18);
        vm.assume(amount > 0);
        whitelistTokens();
        vm.startPrank(users[1]);
        stable.deposit(address(weth), amount);
        vm.expectRevert();
        stable.deposit(address(wbtc), 0);
        vm.stopPrank();
        assertEq(weth.balanceOf(users[1]), 10e18 - amount);
        assertEq(wbtc.balanceOf(users[1]), 10e18);
        assertEq(wbtc.balanceOf(address(stable)), 0);
        assertEq(weth.balanceOf(address(stable)), amount);
    }

    function test_fuzz_withdrawSuccess(uint256 i, uint256 amountERC20, uint256 amountEther) public {
        i = bound(i, 1, 4);
        amountERC20 = bound(amountERC20, 1, 10e18);
        amountEther = bound(amountEther, MIN_DEPOSIT_ETH, 10e18);
        whitelistTokens();
        vm.startPrank(users[i]);
        stable.deposit(address(weth), amountERC20);
        (bool success,) = address(stable).call{value: amountEther}(abi.encodeWithSignature("deposit(address,uint256)", ETHER, 0));
        vm.stopPrank();
        assertEq(weth.balanceOf(users[i]), 10e18 - amountERC20);
        assertEq(stable.getTotalBalance(address(weth)), amountERC20);
        assertEq(stable.getUserBalance(users[i], address(weth)), amountERC20);
        assertEq(users[i].balance, 10e18 - amountEther);
        assertEq(stable.getTotalBalance(ETHER), amountEther);
        assertEq(stable.getUserBalance(users[i], ETHER), amountEther);
        vm.startPrank(users[i]);
        stable.withdraw(ETHER, amountEther);
        stable.withdraw(address(weth), amountERC20);
        vm.stopPrank();
        assertEq(weth.balanceOf(users[i]), 10e18);
        assertEq(stable.getTotalBalance(address(weth)), 0);
        assertEq(stable.getUserBalance(users[i], address(weth)), 0);
        assertEq(users[i].balance, 10e18);
        assertEq(stable.getTotalBalance(ETHER), 0);
        assertEq(stable.getUserBalance(users[i], ETHER), 0);
    }
    
    function test_fuzz_withdrawFailExceedsBalanceERC20(uint256 i, uint256 amountERC20, uint256 amountEther) public {
        i = bound(i, 1, 4);
        amountERC20 = bound(amountERC20, 1, 10e18);
        amountEther = bound(amountEther, MIN_DEPOSIT_ETH, 10e18);
        whitelistTokens();
        vm.startPrank(users[i]);
        stable.deposit(address(weth), amountERC20);
        (bool success,) = address(stable).call{value: amountEther}(abi.encodeWithSignature("deposit(address,uint256)", ETHER, 0));
        vm.stopPrank();
        assertEq(weth.balanceOf(users[i]), 10e18 - amountERC20);
        assertEq(stable.getTotalBalance(address(weth)), amountERC20);
        assertEq(stable.getUserBalance(users[i], address(weth)), amountERC20);
        assertEq(users[i].balance, 10e18 - amountEther);
        assertEq(stable.getTotalBalance(ETHER), amountEther);
        assertEq(stable.getUserBalance(users[i], ETHER), amountEther);
        vm.startPrank(users[i]);
        stable.withdraw(ETHER, amountEther);
        vm.expectRevert();
        stable.withdraw(address(weth), amountERC20 +5);
        vm.stopPrank();
        assertEq(weth.balanceOf(users[i]), 10e18 - amountERC20);
        assertEq(stable.getTotalBalance(address(weth)), amountERC20);
        assertEq(stable.getUserBalance(users[i], address(weth)), amountERC20);
        assertEq(users[i].balance, 10e18);
        assertEq(stable.getTotalBalance(ETHER), 0);
        assertEq(stable.getUserBalance(users[i], ETHER), 0);
    }

    function test_fuzz_withdrawFailExceedsBalanceEther(uint256 i, uint256 amountERC20, uint256 amountEther) public {
        i = bound(i, 1, 4);
        amountERC20 = bound(amountERC20, 1, 10e18);
        amountEther = bound(amountEther, MIN_DEPOSIT_ETH, 10e18);
        whitelistTokens();
        vm.startPrank(users[i]);
        stable.deposit(address(weth), amountERC20);
        (bool success,) = address(stable).call{value: amountEther}(abi.encodeWithSignature("deposit(address,uint256)", ETHER, 0));
        vm.stopPrank();
        assertEq(weth.balanceOf(users[i]), 10e18 - amountERC20);
        assertEq(stable.getTotalBalance(address(weth)), amountERC20);
        assertEq(stable.getUserBalance(users[i], address(weth)), amountERC20);
        assertEq(users[i].balance, 10e18 - amountEther);
        assertEq(stable.getTotalBalance(ETHER), amountEther);
        assertEq(stable.getUserBalance(users[i], ETHER), amountEther);
        vm.startPrank(users[i]);
        vm.expectRevert();
        stable.withdraw(ETHER, amountEther + 1);
        stable.withdraw(address(weth), amountERC20);
        vm.stopPrank();
        assertEq(weth.balanceOf(users[i]), 10e18);
        assertEq(stable.getTotalBalance(address(weth)), 0);
        assertEq(stable.getUserBalance(users[i], address(weth)), 0);
        assertEq(users[i].balance, 10e18 - amountEther);
        assertEq(stable.getTotalBalance(ETHER), amountEther);
        assertEq(stable.getUserBalance(users[i], ETHER), amountEther);
    }
}