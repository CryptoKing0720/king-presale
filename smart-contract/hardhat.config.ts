import { HardhatUserConfig, NetworkUserConfig } from "hardhat/types";
import "@nomicfoundation/hardhat-toolbox-viem";
import "@nomicfoundation/hardhat-ignition-viem";
require("dotenv").config();

const holesky: NetworkUserConfig = {
  url: "https://ethereum-holesky-rpc.publicnode.com",
  chainId: 17000,
  accounts: [process.env.KEY_TESTNET!],
};

const config: HardhatUserConfig = {
  defaultNetwork: "holesky",
  networks: {
    hardhat: {},
    ...{ holesky },
  },
  etherscan: {
    apiKey: {
      holesky: "2VPQC6NNB1AEJI2P3GQA73C9UZ823EFY3F",
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
  solidity: "0.8.24",
  paths: {
    sources: "./contracts",
    tests: "./test",
    cache: "/cache",
    artifacts: "./artifacts",
  },
};

export default config;
