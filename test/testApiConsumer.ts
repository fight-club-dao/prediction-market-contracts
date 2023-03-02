
import { expect } from 'chai';
import { ethers, network } from 'hardhat';

describe("Test 2", function () {
    let user1, user2, user3, user4, user10, borrower, liquidator, usdtOwner;
    let ApiConsumer, apiConsumer;


    before(async function () {
        [user1, user2, borrower, user3, user4, user10, liquidator, usdtOwner] = await ethers.getSigners();
        ApiConsumer = await ethers.getContractFactory('APIConsumer');
        apiConsumer = await ApiConsumer.deploy();
    })

    it("check", async function () {
        let volume = await apiConsumer.volume();
        console.log(volume)
        expect(volume).to.be.equal(0);

    });
});
