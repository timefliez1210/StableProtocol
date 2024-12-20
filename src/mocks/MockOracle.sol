//SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

contract MockOracle {
    uint256 price = 4232;

    function setPriceWeth(uint256 _price) external {
        price = _price;
    }


    function getPrice(address _asset) public view returns (uint256) {
        return price;
    }
}
