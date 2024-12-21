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
        selectors[0] = handler.erc20Workflow.selector;
        targetSelector(FuzzSelector({addr: address(handler), selectors: selectors}));
        targetContract(address(handler));
    }

    function test_fuzz() public {
        console2.log("test_fuzz");
    }
}
