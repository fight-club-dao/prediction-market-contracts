
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
    const contractName = "FunctionsConsumer"
    //const contractName = "MyFirstContract"
    let fc_address = "0xd3059769E3F6de1484BA01d8bfdD2910E584B56F"
    let predictionMarketAddress = "0xDF11378E7f5708Bab56c8925E086096Fa54E378C";
    const [deployer] = await ethers.getSigners()

    let fm = await ethers.getContractAt(contractName,fc_address);
    await fm.setPMManager(predictionMarketAddress);
}
main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });


