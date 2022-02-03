// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Campaign {
    struct Request {
        string description;
        address recipient;
        uint256 value;
        bool complete;
    }

    address public manager;
    uint256 public minimumContribution;
    address[] public approvers;
    Request[] public requests;

    modifier minimum() {
        require(
            msg.value >= minimumContribution,
            "Contributed amount is less than minimum amount required"
        );
        _;
    }

    modifier managerOnly() {
        require(msg.sender == manager, "Only manager can perform this action");
        _;
    }

    constructor(uint256 minimumAmount) {
        manager = msg.sender;
        minimumContribution = minimumAmount;
    }

    function contribute() public payable minimum {
        approvers.push(msg.sender);
    }

    function createRequest(
        string memory description,
        uint256 value,
        address recipient
    ) public managerOnly {
        requests.push(
            Request({
                description: description,
                recipient: recipient,
                value: value,
                complete: false
            })
        );
    }
}
