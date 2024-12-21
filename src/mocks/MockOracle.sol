//SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

contract MockOracle {
    uint256 price;

    constructor() {
        setPriceWeth(4232);
    }

    function setPriceWeth(uint256 _price) public {
        price = _price;
    }

    function getPrice() public view returns (uint256) {
        return price;
    }
}
