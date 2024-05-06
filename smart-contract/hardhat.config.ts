import { NetworkUserConfig, HardhatUserConfig } from "hardhat/types";
import "@nomicfoundation/hardhat-toolbox";
require("dotenv").config();

const holesky: NetworkUserConfig = {
  url: "https://ethereum-holesky-rpc.publicnode.com",
  chainId: 17000,
  accounts: [process.env.KEY_TESTNET!],
};

const config: HardhatUserConfig = {
  defaultNetwork: "holesky",
  solidity: {
    compilers: [{ version: "0.8.24" }],
    settings: {
      optimizer: {
        enabled: false,
        runs: 99999,
      },
    },
  },
  networks: {
    hardhat: {},
    ...(process.env.KEY_TESTNET && { holesky }),
  },
  etherscan: {
    apiKey: {
      holesky: process.env.ETHERSCAN_API_KEY,
    },
    customChains: [
      {
        network: "holesky",
        chainId: 17000,
        urls: {
          apiURL: "https://api-holesky.etherscan.io/api",
          browserURL: "https://holesky.etherscan.io",
        },
      },
    ],
  },
  paths: {
    sources: "./contracts",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts",
  },
};

export default config;
