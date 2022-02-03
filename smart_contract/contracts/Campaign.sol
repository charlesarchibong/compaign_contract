// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Campaign {
    address public manager;
    uint256 public minimumContribution;
    address[] public approvers;

    constructor(uint256 minimumAmount) {
        manager = msg.sender;
        minimumContribution = minimumAmount;
    }

    function contribute() public payable minimum {
        approvers.push(msg.sender);
    }

    modifier minimum() {
        require(
            msg.value > minimumContribution,
            "Contributed amount is less than minimum amount required"
        );
        _;
    }
}
