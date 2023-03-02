
import {ethers} from "hardhat";
const fs = require('fs')
const path = require('path')
// import fs from "fs";
// import path from "path";

async function main() {
    let signers = await ethers.getSigners();
    console.log(signers[0].address)
    const provider = ethers.getDefaultProvider()
    const balance = await provider.getBalance(signers[0].address);

    // await contract.requestVolumeData({gasLimit: "3000000"});


    console.log(balance);



}
main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

