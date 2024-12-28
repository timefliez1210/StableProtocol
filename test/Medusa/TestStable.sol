//SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import {Setup} from "./Setup.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

contract TestStable is Setup {
    function testDeposit(uint256 amount, uint256 index) public {
        index = between(index, 0, 2);
        address asset = stable.allowlist(index);
        stable.deposit(asset, amount);
        assert(ERC20Mock(asset).balanceOf(address(stable)) == amount);
    }

    function testWithdraw(uint256 amount, uint256 index) public {
        index = between(index, 0, 2);
        address asset = stable.allowlist(index);
        uint256 balanceBefore = ERC20Mock(asset).balanceOf(address(stable));
        stable.withdraw(asset, amount);
        uint256 balanceAfter = ERC20Mock(asset).balanceOf(address(stable));
        assert(balanceAfter == balanceBefore - amount);
    }
    
    function testMintStable(uint256 amountToMint, uint256[3] calldata amountToSupply) public {
        address[3] memory assets = [stable.allowlist(0), stable.allowlist(1), stable.allowlist(0)];
        stable.mintStable(amountToMint, amountToSupply, assets);
        assert(stable.getStableLendingHealthFactor() >= 100);
    }

    function testRepayStable(uint256 amount) public {
        uint256 healthFactorBefore = stable.getStableLendingHealthFactor();
        stable.repayStable(amount);
        uint256 healthFactorAfter = stable.getStableLendingHealthFactor();
        assert(healthFactorAfter > healthFactorBefore);
    }

    function testUnlockColleteral(uint256 index, uint256 amount) public {
        index = between(index, 0, 2);
        address asset = stable.allowlist(index);
        stable.unlockColleteral(asset, amount);
        assert(stable.getStableLendingHealthFactor() > 100);
    }
}
