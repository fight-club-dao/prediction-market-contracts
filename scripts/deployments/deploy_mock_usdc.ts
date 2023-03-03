

import {ethers} from "hardhat";
const fs = require('fs')
const path = require('path')

async function main() {

    let Contract = await ethers.getContractFactory('MockToken');
    let contract = await Contract.deploy("USDC", "USDC", 6);
    await contract.deployed();
    console.log("contract deployed to: ",contract.address);



}
main()
.then(() => process.exit(0))
.catch(error => {
console.error(error);
process.exit(1);
});

