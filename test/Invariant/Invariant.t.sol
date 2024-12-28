//SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Test, console2} from "forge-std/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
import {Handler} from "./Handler.t.sol";

contract Invariant is StdInvariant, Test {
    Handler handler;
    function setUp() public {
        // Setting up the Handler for the invariant
        handler = new Handler();
        bytes4[] memory selectors = new bytes4[](1);
        selectors[0] = handler.testDeposit.selector;
        targetSelector(
            FuzzSelector({addr: address(handler), selectors: selectors})
        );
        targetContract(address(handler));
    }
    function statefulFuzz_testDeposit() public view {
        assertEq(handler.balanceBeforeStable(), 0);
        assertEq(handler.balanceAfterStable(), (handler.balanceBeforeUser() - handler.balanceAfterUser()));
    }
}
