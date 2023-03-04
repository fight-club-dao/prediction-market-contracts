
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
    let fm_address = "0x7F07648363865301e4f4C83dcB09eD894F1A4A2D"
    let predictionMarketAddress = "";
    const [deployer] = await ethers.getSigners()

    let fm = await ethers.getContractAt('FundManager',fm_address);
    await fm.setBorrower(predictionMarketAddress);
}
main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });


