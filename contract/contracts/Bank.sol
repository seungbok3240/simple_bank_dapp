// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract Bank {
    int256 balance;

    constructor() {
        balance = 0;
    }

    function getBalance() public view returns (int256) {
        return balance;
    }

    function deposit(int256 money) public {
        balance = balance + money;
    }

    function withdraw(int256 money) public {
        balance = balance - money;
    }
}
