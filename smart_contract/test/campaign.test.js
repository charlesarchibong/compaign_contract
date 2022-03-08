const ganache = require("ganache-cli");
const Web3 = require("web3");
const assert = require("assert");

const web3 = new Web3(ganache.provider());

const campaignFactory = require("../../smart_contract/src/abis/CampaignFactory.json");
const campaign = require("../../smart_contract/src/abis/Campaign.json");

let accounts;
let factory;
let campaignAddress;
let campaignInstance;

beforeEach(async () => {

    accounts = await web3.eth.getAccounts();
    factory = await new web3.eth.Contract(campaignFactory.abi).deploy({ data: campaignFactory.bytecode }).send({ from: accounts[0], gas: "3000000" })
    await factory.methods.createCampaign("10000").send({ from: accounts[0], gas: "3000000" });
    [campaignAddress] = await factory.methods.getDeployedCampaigns().call();
    campaignInstance = await new web3.eth.Contract(campaign.abi, campaignAddress);
})

describe("Campaign", () => {
    it("deploys a factory and a campaign", () => {
        assert.ok(factory.options.address);
        assert.ok(campaignInstance.options.address);
    });

    it("marks caller as the campaign manager", async () => {
        const manager = await campaignInstance.methods.manager().call();
        assert.equal(accounts[0], manager);
    });

    it("allows people to contribute money and marks them as approvers", async () => {
        await campaignInstance.methods.contribute().send({ value: "20000", from: accounts[1] });
        const isContributor = await campaignInstance.methods.approvers(accounts[1]).call();
        assert(isContributor);
    })


    it("requires a minimum contribution", async () => {
        try {
            await campaignInstance.methods.contribute().send({ value: "5", from: accounts[1] });
            assert(false);
        } catch (err) {
            assert(err);
        }
    })

    it("allows a manager to make a payment request", async () => {
        await campaignInstance.methods.createRequest("Get foods and tools", "100", accounts[1]).send({ from: accounts[0], gas: "3000000" });
        const request = await campaignInstance.methods.requests(0).call();
        assert.equal("Get foods and tools", request.description);
    });

    it("processes requests", async () => {
        await campaignInstance.methods.contribute().send({ from: accounts[0], value: web3.utils.toWei("10", "ether") });
        await campaignInstance.methods.createRequest("A", web3.utils.toWei("5", "ether"), accounts[1]).send({ from: accounts[0], gas: "3000000" });
        await campaignInstance.methods.approveReques(0).send({ from: accounts[0], gas: "3000000" });
        await campaignInstance.methods.finalizeRequest(0).send({ from: accounts[0], gas: "3000000" });
        let balance = await web3.eth.getBalance(accounts[1]);
        balance = web3.utils.fromWei(balance, "ether");
        balance = parseFloat(balance);
        assert(balance > 104);
    });
})