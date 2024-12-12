//SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

abstract contract Utils {
    error NotOwner(address);

    address public constant ETHER = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    uint256 public constant MIN_DEPOSIT_ETH = 1e6;
    address owner;

    modifier onlyOwner() {
        if(msg.sender != owner) {
            revert NotOwner(msg.sender);
        }
        _;
    }

    modifier nonReentrant {
        assembly {
            if tload(0) { revert(0, 0) }
            tstore(0, 1)
        }
        _;
        assembly {
            tstore(0, 0)
        }
    }
}