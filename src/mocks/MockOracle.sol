//SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

contract MockOracle {
    function getPrice(address _asset) public view returns (uint256) {
        return 4232;
    }
}
