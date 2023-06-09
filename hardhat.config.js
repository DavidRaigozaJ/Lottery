require("@nomiclabs/hardhat-waffle")
require("@nomiclabs/hardhat-etherscan")
require("hardhat-deploy")
require("solidity-coverage")
require("hardhat-gas-reporter")
require("hardhat-contract-sizer")
require("dotenv").config()


const SEPOLIA_RPC_INFURA = process.env.SEPOLIA_RPC_INFURA || "https:eth-sepolia/example"
const SEPOLIA_PRIVATE_KEY = process.env.SEPOLIA_PRIVATE_KEY || "0xKey"



/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  dafaulNetwork: "hardhat",
  networks: {
    hardhat: {
      chainId: 31337,
      blockConfirmations: 1,
    },
    sepolia: {
      url: SEPOLIA_RPC_INFURA,
      accounts: [SEPOLIA_PRIVATE_KEY],
      chainId: 11155111,
      blockConfirmations: 6,
  },

  },
  solidity: "0.8.7",
  namedAccounts: {
    deployer: {
      default: 0,

    },
    player: {
      default: 1,
    },
  },
};
