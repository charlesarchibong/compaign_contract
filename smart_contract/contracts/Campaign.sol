// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract CampaignFactory {
    address[] public deployedCampaigns;

    function createCampaign(uint256 minimusAmount) public payable {
        Campaign campaign = new Campaign(minimusAmount, msg.sender);
        deployedCampaigns.push(address(campaign));
    }

    function getDeployedCampaigns() public view returns (address[] memory) {
        return deployedCampaigns;
    }
}

contract Campaign {
    struct Request {
        string description;
        address recipient;
        uint256 value;
        bool complete;
        uint256 noOfApprovals;
        mapping(address => bool) approvals;
    }

    address public manager;
    uint256 public minimumContribution;

    mapping(address => bool) public approvers;
    Request[] public requests;
    uint256 public approversCount;

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

    constructor(uint256 minimumAmount, address creator) {
        manager = creator;
        minimumContribution = minimumAmount;
    }

    function contribute() public payable minimum {
        approvers[msg.sender] = true;
        approversCount++;
    }

    function createRequest(
        string memory description,
        uint256 value,
        address recipient
    ) public managerOnly {
        Request storage newRequest = requests.push();
        newRequest.value = value;
        newRequest.recipient = recipient;
        newRequest.description = description;
        newRequest.complete = false;
        newRequest.noOfApprovals = 0;
    }

    function approveReques(uint256 index) public {
        Request storage request = requests[index];
        require(
            approvers[msg.sender],
            "You must contribute to the campaign before you can vote"
        );
        require(!request.approvals[msg.sender], "You can only vote once");
        request.approvals[msg.sender] = true;
        request.noOfApprovals++;
    }

    function finalizeRequest(uint256 index) public payable managerOnly {
        Request storage request = requests[index];
        require(request.complete == false, "Request is already finalized");
        require(
            request.noOfApprovals > approversCount / 2,
            "Not enough approvals, request must have 50% approvers before it can be finalized"
        );
        payable(request.recipient).transfer(request.value);
        request.complete = true;
    }
}
