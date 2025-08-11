import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "@nomicfoundation/hardhat-verify";
import * as dotenv from "dotenv";

dotenv.config();

const config: HardhatUserConfig = {
  solidity: {
    version: "0.7.6",
    settings: {
      optimizer: {
        enabled: true,
        runs: 800,
      },
      metadata: {
        // do not include the metadata hash, since this is machine dependent
        // and we want all generated code to be deterministic
        // https://docs.soliditylang.org/en/v0.7.6/metadata.html
        bytecodeHash: "none",
      },
    },
  },
  networks: {
    hardhat: {
      allowUnlimitedContractSize: false,
    },
    localhost: {
      url: "http://127.0.0.1:8545",
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
    },
    // NERO链网络配置 - 请根据实际情况调整
    "nero-testnet": {
      url: process.env.NERO_TESTNET_RPC || "https://rpc-testnet.nero.network", // 更新为实际的RPC端点
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
      chainId: 1002, // 请根据NERO测试网的实际链ID调整
      gasPrice: 20000000000, // 20 gwei
      timeout: 60000, // 增加超时时间
    },
    "nero-mainnet": {
      url: process.env.NERO_MAINNET_RPC || "https://rpc.nero.network", // 更新为实际的RPC端点
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
      chainId: 1001, // 请根据NERO主网的实际链ID调整
      gasPrice: 20000000000, // 20 gwei
      timeout: 60000,
    },
    // 备用测试网络
    "polygon-mumbai": {
      url: "https://rpc-mumbai.maticvigil.com",
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
      chainId: 80001,
    },
    "bsc-testnet": {
      url: "https://data-seed-prebsc-1-s1.binance.org:8545",
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
      chainId: 97,
    },
  },
  etherscan: {
    // 根据NERO链的区块浏览器API配置
    apiKey: {
      "nero-testnet": process.env.NERO_EXPLORER_API_KEY || "YOUR_API_KEY",
      "nero-mainnet": process.env.NERO_EXPLORER_API_KEY || "YOUR_API_KEY",
      polygonMumbai: process.env.POLYGONSCAN_API_KEY || "YOUR_API_KEY",
      bscTestnet: process.env.BSCSCAN_API_KEY || "YOUR_API_KEY",
    },
    customChains: [
      {
        network: "nero-testnet",
        chainId: 1002, // 根据实际情况调整
        urls: {
          apiURL: "https://explorer-api-testnet.nero.network/api", // 更新为实际的API端点
          browserURL: "https://explorer-testnet.nero.network"
        }
      },
      {
        network: "nero-mainnet",
        chainId: 1001, // 根据实际情况调整
        urls: {
          apiURL: "https://explorer-api.nero.network/api",
          browserURL: "https://explorer.nero.network"
        }
      }
    ]
  },
  gasReporter: {
    enabled: process.env.REPORT_GAS !== undefined,
    currency: "USD",
  },
  typechain: {
    outDir: "typechain-types",
    target: "ethers-v6",
  },
};

export default config; 