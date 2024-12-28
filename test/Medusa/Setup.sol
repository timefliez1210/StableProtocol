//SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import {Stable} from "../../src/Stable.sol";
import {StableUSD} from "../../src/tokens/StableUSD.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

contract Setup {
    Stable stable;
    StableUSD sUSD;
    ERC20Mock weth;
    ERC20Mock wbtc;

    constructor() {
        stable = new Stable();
        sUSD = new StableUSD(address(stable));
        weth = new ERC20Mock();
        wbtc = new ERC20Mock();
        stable.whitelistTokens(address(weth));
        stable.whitelistTokens(address(wbtc));
        stable.whitelistTokens(address(weth));
        stable.whitelistTokens(address(wbtc));
    }

    function between(uint256 value, uint256 low, uint256 high) public returns (uint256) {
        if (value < low || value > high) {
            uint256 ans = low + (value % (high - low + 1));
            return ans;
        }
        return value;
    }
}