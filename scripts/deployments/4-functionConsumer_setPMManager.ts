
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
    let fc_address = "0xaE4419B48Ec064f85BC24BDfA822C3868Cf8334c"
    let predictionMarketAddress = "";
    const [deployer] = await ethers.getSigners()

    let fm = await ethers.getContractAt('FunctionConsumer',fc_address);
    await fm.setPMManager(predictionMarketAddress);
}
main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });


