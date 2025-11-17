import { configVariable, task, type HardhatUserConfig } from "hardhat/config";
import hardhatToolboxMochaEthersPlugin from "@nomicfoundation/hardhat-toolbox-mocha-ethers";

const getExplorerApiKey = (chainId: number) => {
  let apiKey;
  if (chainId === 25) {
    apiKey = configVariable("CRONOS_EXPLORER_MAINNET_API_KEY");
  } else if (chainId === 338) {
    apiKey = configVariable("CRONOS_EXPLORER_TESTNET_API_KEY");
  }
  if (!apiKey) {
    throw Error("Explorer API Key Not Set for chainId: " + chainId);
  }
  return apiKey;
}

const getHDWallet = () => {
  const PRIVATE_KEY = configVariable("PRIVATE_KEY");
  if (PRIVATE_KEY) {
    return [PRIVATE_KEY]
  }
  throw Error("Private Key Not Set!");
}

const config: HardhatUserConfig = {
  plugins: [hardhatToolboxMochaEthersPlugin],
  solidity: {
    profiles: {
      default: {
        version: "0.8.20",
      },
      production: {
        version: "0.8.20",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
    },
  },
  networks: {
    cronos: {
      chainId: 25,
      type: "http",
      url: "https://evm.cronos.org/",
      accounts: getHDWallet(),
      chainType: "l1",
    },
    cronosTestnet: {
      chainId: 338,
      type: "http",
      url: "https://evm-t3.cronos.org/",
      accounts: getHDWallet(),
      chainType: "l1",
    },
  },
  verify: {
    etherscan: {
      apiKey: getExplorerApiKey(338),
    },
  },
  chainDescriptors: {
    25: {
      name: "cronos",
      chainType: "l1",
      blockExplorers: {
        etherscan: {
          name: "cronos",
          url: "https://explorer.cronos.org",
          apiUrl: "https://explorer-api.cronos.org/mainnet/api/v1/hardhat/contract"
        },
      },
    },
    338: {
      name: "cronosTestnet",
      chainType: "l1",
      blockExplorers: {
        etherscan: {
          name: "cronosTestnet",
          url: "https://explorer.cronos.org/testnet",
          apiUrl: "https://explorer-api.cronos.org/testnet/api/v1/hardhat/contract"
        },
      },
    },
  }
};

export default config;
