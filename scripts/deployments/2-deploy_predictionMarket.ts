import {
    UNISWAPV2_ROUTER_ADDRESS,
    UNISWAPV2_FACTORY_ADDRESS,
} from '../../helpers/constants-goerli';

import {ethers} from "hardhat";
const fs = require('fs')
const path = require('path')
// import fs from "fs";
// import path from "path";

const FunctionsConsumer = "0x10f86aedcFA3e5bc006E8775d17B3aC38781643e"
const FundManager = "0xA574f7815517E0487ab7cAe93455d9e8173a99d4"
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

