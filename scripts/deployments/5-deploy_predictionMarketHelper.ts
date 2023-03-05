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

const PredictionMarketManager = "0x246aaFB2Fe5B3Cc9009a2097e5e6D9649f3176ba"
async function main() {

    let CONTRACT = await ethers.getContractFactory('PMHelper');
    let contract = await CONTRACT.deploy(PredictionMarketManager);
    await contract.deployed();
    console.log("contract deployed to: ",contract.address);



}
main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

