//SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import {Test} from "forge-std/Test.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {Stable} from "../../src/Stable.sol";
import {Utils} from "../../src/Utils.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract BaseTest is Test, Utils {
    ERC20Mock weth;
    ERC20Mock wbtc;
    address[5] users;

    Stable stable;

    function setUp() public {
        owner = makeAddr("owner");
        vm.prank(owner);
        stable = new Stable();
        weth = new ERC20Mock();
        wbtc = new ERC20Mock();
        makeUsers(5);
    }

    function makeUsers(uint256 _userCount) internal {
        for (uint256 i = 1; i < _userCount; i++) {
            string memory user = string.concat("depositor", Strings.toString(i));
            users[i] = makeAddr(user);
            weth.mint(users[i], 10e18);
            wbtc.mint(users[i], 10e18);
            vm.startPrank(users[i]);
            weth.approve(address(stable), 10e18);
            wbtc.approve(address(stable), 10e18);
            vm.deal(users[i], 10e18);
            vm.stopPrank();
        }
    }

    function whitelistTokens() public {
        vm.startPrank(owner);
        stable.whitelistTokens(address(weth));
        stable.whitelistTokens(address(wbtc));
        vm.stopPrank();
        assertEq(stable.isWhitelisted(address(weth)), true);
        assertEq(stable.isWhitelisted(address(wbtc)), true);
    }
}
