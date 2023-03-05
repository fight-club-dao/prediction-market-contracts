
<h1 align="center">Welcome to Fight Club Prediction Market Contracts</h1>
<p align="center">
  <img alt="Version" src="https://img.shields.io/badge/version-1.0.0-blue.svg?cacheSeconds=2592000" />
</p>

> Fight Club EVM contracts

### 🏠 [Homepage](https://fightclubdao.carrd.co/)

### ✨ [Demo](https://fightclubapp.vercel.app/markets)

## How it works?

This prediction market is a decentralized and tokenized prediction market that is controlled by a DAO.
For every match, the Prediction Market Manger contract will create 2 new tokens. one for each side of the match.
it will deploy those 2 token to Uniswap Pools.
The Contract will borrow USDC in order to have the initial 10K needed to add liquidity to the 2 uniswap pools.
It will borrow it from our DAO's pool (Only on goerli - built with Huma Finance contracts).
After the deployment, A new match will be created and users will be able and predict who is going to win just by buying one of the players token.
If your player won, congrats, you can go to the website and claim your rewards.
the rewards will be the liquidity of the losing token minus the initial liquidity that is going to pay back to borrowed usdc+intrest.
also, 10% of the losing funds will go back to the pool and to the DAO.
the rest of the money will be split between the winning token holders based on their holdings.
If you won, after you claim you can either sell your token or keep holding them for the next match of your player.

Have fun and enjoy the game!


## Setup development environment



### Checkout this repository

```sh
clone repository
```

### Install the dependencies

```sh
yarn install
```

### Compile and run tests
add .env file with the relavant keys

```sh
npx hardhat compile
fork mainnet: npx hardhat node
```

Deployed contract addresses are in `deployments/goerli-deployed-contracts.json`.
Deployed contract addresses are in `deployments/base-deployed-contracts.json`.
Deployed contract addresses are in `deployments/sepolia-deployed-contracts.json`.
Deployed contract addresses are in `deployments/scroll-deployed-contracts.json`.


## Author
Fight Club
Amitay Bohadana
amitaybohadana@gmail.com
- Twitter: [@0xBudi]
