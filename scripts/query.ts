
import {ethers} from "hardhat";
const fs = require('fs')
const path = require('path')
// import fs from "fs";
// import path from "path";

async function main() {

    let contract = await ethers.getContractAt('FunctionsConsumer',"0x27061b613A56c1a59b138e52186D5f5Cd78d438a");
    console.log(contract.address);
    // console.log(contract);
    let res = await contract.latestResponse();
    let res2 = await contract.getMatchResults(1);

    // await contract.requestVolumeData({gasLimit: "3000000"});


    console.log(res);
    console.log(res2);


}
main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

