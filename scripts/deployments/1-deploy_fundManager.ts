
import {ethers} from "hardhat";
const fs = require('fs')
const path = require('path')
// import fs from "fs";
// import path from "path";
import {
    CIRCLE_MESSAGE_TRANSMITTER,
    CIRCLE_TOKEN_MESSANGER, HUMA_CREDIT_POOL,
    USDC_ADDRESS,
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

    const deployedContract = await consumerContract.deploy("0x23a8C72d7f7A5B11A8b9bFbb50BB61550531Be2B", HUMA_CREDIT_POOL , CIRCLE_TOKEN_MESSANGER, CIRCLE_MESSAGE_TRANSMITTER, "0x23a8C72d7f7A5B11A8b9bFbb50BB61550531Be2B", true)

    console.log("Deployed address:", deployedContract.address)
}
main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });


