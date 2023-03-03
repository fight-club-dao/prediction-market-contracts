import {
    USDT_ADDRESS,
    WBTC_ADDRESS,
    UNISWAPV2_ROUTER_ADDRESS,
    UNISWAPV2_FACTORY_ADDRESS,
    USDT_OWNER, FUNCTIONS_CONSUMER_MUMBAI
} from '../../helpers/constants';

import {ethers} from "hardhat";
const fs = require('fs')
const path = require('path')
// import fs from "fs";
// import path from "path";

const FunctionsConsumer = "0xb71c52BA5E0690A7cE3A0214391F4c03F5cbFB0d"
async function main() {

    let PMMANGER = await ethers.getContractFactory('PredictionMarketManager');
    let pmManager = await PMMANGER.deploy(UNISWAPV2_FACTORY_ADDRESS, UNISWAPV2_ROUTER_ADDRESS, FunctionsConsumer);
    await pmManager.deployed();
    console.log("pmManager deployed to: ",pmManager.address);



}
main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

