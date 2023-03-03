
import {ethers} from "hardhat";
const fs = require('fs')
const path = require('path')
// import fs from "fs";
// import path from "path";
const UniswapFactory = "0xd4790c528848e3b789196ba90e3abca8aa1292f9"
const UniswapV2Router = "0xb71c52BA5E0690A7cE3A0214391F4c03F5cbFB0d"
const FunctionsConsumer = "0xb71c52BA5E0690A7cE3A0214391F4c03F5cbFB0d"
async function main() {

    let PMMANGER = await ethers.getContractFactory('MatchData');
    let pmManager = await PMMANGER.deploy();
    await pmManager.deployed();



}
main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

