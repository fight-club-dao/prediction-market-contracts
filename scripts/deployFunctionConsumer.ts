
import {ethers} from "hardhat";
const fs = require('fs')
const path = require('path')
// import fs from "fs";
// import path from "path";


async function main() {
    // The oracle address on Polygon Mumbai
    // See https://docs.chain.link/chainlink-functions/supported-networks
    // for a list of supported networks and addresses.
    let oracle_sepolia;
    let oracle_mumbai = 	"0xeA6721aC65BCeD841B8ec3fc5fEdeA6141a0aDE4";
    const oracleAddress = oracle_mumbai

    // Set your contract name.
    const contractName = "FunctionsConsumer"
    //const contractName = "MyFirstContract"

    const [deployer] = await ethers.getSigners()

    console.log("Deploying contracts with the account:", deployer.address)

    console.log("Account balance:", (await deployer.getBalance()).toString())

    const consumerContract = await ethers.getContractFactory(contractName)

    const deployedContract = await consumerContract.deploy(oracleAddress)

    console.log("Deployed Functions Consumer address:", deployedContract.address)
}
main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });


