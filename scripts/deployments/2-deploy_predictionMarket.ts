import {
    UNISWAPV2_ROUTER_ADDRESS,
    UNISWAPV2_FACTORY_ADDRESS,
} from '../../helpers/constants-goerli';

import {ethers} from "hardhat";
const fs = require('fs')
const path = require('path')
// import fs from "fs";
// import path from "path";

const FunctionsConsumer = "0xaE4419B48Ec064f85BC24BDfA822C3868Cf8334c"
const FundManager = "0x7F07648363865301e4f4C83dcB09eD894F1A4A2D"
async function main() {

    let PMMANGER = await ethers.getContractFactory('PredictionMarketManager');
    let pmManager = await PMMANGER.deploy(UNISWAPV2_FACTORY_ADDRESS, UNISWAPV2_ROUTER_ADDRESS, FunctionsConsumer,FundManager);
    await pmManager.deployed();
    console.log("pmManager deployed to: ",pmManager.address);



}
main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

