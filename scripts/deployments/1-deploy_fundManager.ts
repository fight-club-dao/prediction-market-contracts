
import {ethers} from "hardhat";
const fs = require('fs')
const path = require('path')
// import fs from "fs";
// import path from "path";
import {
    USDC_ADDRESS
} from '../../helpers/constants-goerli';

async function main() {
    // The oracle address on Polygon Mumbai
    // See https://docs.chain.link/chainlink-functions/supported-networks
    // for a list of supported networks and addresses.

    // Set your contract name.
    const contractName = "FundManager"
    //const contractName = "MyFirstContract"

    const [deployer] = await ethers.getSigners()

    console.log("Deploying contracts with the account:", deployer.address)

    console.log("Account balance:", (await deployer.getBalance()).toString())

    const consumerContract = await ethers.getContractFactory(contractName)

    const deployedContract = await consumerContract.deploy(USDC_ADDRESS, "0xE42C3ac195DE958B38c323DD14a47894AB7c422c")

    console.log("Deployed address:", deployedContract.address)
}
main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });


