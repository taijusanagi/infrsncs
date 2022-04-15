import * as dotenv from "dotenv";

import { HardhatUserConfig } from "hardhat/config";
import "@nomiclabs/hardhat-etherscan";
import "@nomiclabs/hardhat-waffle";
import "@typechain/hardhat";
import "hardhat-gas-reporter";
import "solidity-coverage";

import "./tasks/register";

import networks from "./network.json";

dotenv.config();

const accounts =
  process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [];

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.4",
    settings: {
      optimizer: {
        enabled: true,
        runs: 1,
      },
    },
  },
  networks: {
    ethereum_testnet: {
      url: networks.ethereum_testnet.rpc,
      accounts,
    },
    polygon_mainnet: {
      url: networks.polygon_mainnet.rpc,
      accounts,
    },
    polygon_testnet: {
      url: networks.polygon_testnet.rpc,
      accounts,
    },
    bsc_mainnet: {
      url: networks.bsc_mainnet.rpc,
      accounts,
    },
    bsc_testnet: {
      url: networks.bsc_testnet.rpc,
      accounts,
    },
  },
  gasReporter: {
    enabled: process.env.REPORT_GAS !== undefined,
    currency: "USD",
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY,
  },
};

export default config;
