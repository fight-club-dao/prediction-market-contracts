import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "@nomiclabs/hardhat-etherscan";
// @ts-ignore
const PK = ""
const ALCHEMY_KEY = process.env.ALCHEMY_KEY || '';
const MNEMONIC = process.env.MNEMONIC || '';

require('dotenv').config();

const config: HardhatUserConfig = {
  solidity: {
    compilers:[
        {
          version: "0.8.7",
          settings: {
            optimizer: {
              enabled: true,
              runs: 1_000,
            },
          },
        },
        {
          version: '0.8.17',
          settings: {
            optimizer: {
              enabled: true,
              runs: 200,
            },
          },
        },
      {
        version: '0.8.9',
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
      {
        version: "0.6.6",
        settings: {
          optimizer: {
            enabled: true,
            runs: 1_000,
          },
        },
      },
      {
        version: "0.4.24",
        settings: {
          optimizer: {
            enabled: true,
            runs: 1_000,
          },
        },
      }

    ],

  },
  networks: {
    coverage: {
      url: 'http://localhost:8555',
    },
    hardhat: {
      forking: {
        url: "https://eth-mainnet.alchemyapi.io/v2/iK90jGtrwumtlgRlWWGbwW0Ep0I8cWLN",
        // url: "https://polygon-mumbai.g.alchemy.com/v2/ZhTv-qMlQgowh84uTZJazc6iVSEeyKmK",


      }
    },
    mainnet: {
      // Infura public nodes
      url: 'https://eth-mainnet.g.alchemy.com/v2/oH-fGxrqElflfNUB9tWdIWOZUuEYQZSU',
      accounts:{
        mnemonic: MNEMONIC
      } ,
      chainId: 1,
      gasPrice: 18000000000
    },
    scroll: {
      url: "https://scroll-prealpha.unifra.io/v1/df6399363f0a4f0ba72fd950e365e7a6" ?? "UNSET",
      accounts: [process.env.PK || PK],
    },
    goerli: {
      // Infura public nodes
      url: 'https://eth-goerli.g.alchemy.com/v2/SCDgqVqpOzP_2_2Oj-C8jhug9Gw8FGnn',
      accounts: [process.env.PK || PK],
      chainId: 5,
      gasPrice: 13000000000,
      // timeout: 50000,

    },
    mumbai: {
      url: 'https://polygon-mumbai.g.alchemy.com/v2/ZhTv-qMlQgowh84uTZJazc6iVSEeyKmK',
      accounts: [process.env.PK || PK],
      chainId: 80001,
      gasPrice: 110000000000, // 44 GWEI gas price for deployment.
      timeout: 10000000
    },
    sepolia: {
      // Infura public nodes
      url: 'https://sepolia.infura.io/v3/4ebe2e09ef2e49c692dd19d27b46ef39',
      accounts: [process.env.PK || PK],
      gasPrice: 5000000000,
      timeout: 50000,

    },
    base: {
      // Infura public nodes
      url: 'https://red-falling-sanctuary.base-goerli.discover.quiknode.pro/7ebe31ebd31c41b0f4a9e36fef001ba100a7cbea/',
      accounts: [process.env.PK || PK],
      gasPrice: 5000000000,
      timeout: 50000,

    },

  },
  etherscan: {
    // Your API key for Etherscan
    // Obtain one at https://etherscan.io/
    apiKey: process.env.ETHERSCAN_API_KEY
  }
};



export default config;
