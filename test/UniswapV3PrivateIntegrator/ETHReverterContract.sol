// SPDX-License-Identifier: MIT
pragma solidity >=0.8.25;

contract ETHReverterContract {

    constructor() {}

    receive() external payable {
        require(msg.sender == address(0));
    }
}
