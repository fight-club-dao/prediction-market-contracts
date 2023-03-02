
import {ethers} from "hardhat";
const fs = require('fs')
const path = require('path')
// import fs from "fs";
// import path from "path";

async function main() {

    let Contract = await ethers.getContractFactory('APIConsumer');

    let contract = await Contract.deploy();
    await contract.deployed();

    console.log(contract.address);

}
main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });




// function getSavedContractAddresses() {
//     let json
//
//     try {
//
//         json = fs.readFileSync(path.join(__dirname, `../deployments/contract-addresses.json`))
//     } catch (err) {
//         json = '{}'
//     }
//     return JSON.parse(json)
// }
//
// function saveContractAddress(network, contract, address) {
//     const addrs = getSavedContractAddresses()
//     addrs[network] = addrs[network] || {}
//     addrs[network][contract] = address;
//     console.log(addrs)
//     fs.writeFileSync(path.join(__dirname, `../deployments/contract-addresses.json`), JSON.stringify(addrs, null, '    '))
// }