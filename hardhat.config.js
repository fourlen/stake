require('dotenv').config()

require("@nomiclabs/hardhat-ethers")
require('hardhat-docgen')
require('hardhat-deploy')
require("@nomiclabs/hardhat-waffle")
require("@nomiclabs/hardhat-web3")
require("@nomiclabs/hardhat-etherscan")
require("solidity-coverage")
require("hardhat-gas-reporter")
require("hardhat-tracer");
const { BigNumber } = require("ethers");

const {INFURA_ID_PROJECT, ETHERSCAN_API_KEY, ACCOUNT_SECRET_KEY, REPORT_GAS} = process.env;
const kovanURL = `https://kovan.infura.io/v3/${INFURA_ID_PROJECT}`
const goerliURL = `https://goerli.infura.io/v3/${INFURA_ID_PROJECT}`
const rinkebyURL = `https://rinkeby.infura.io/v3/${INFURA_ID_PROJECT}`
const mainnetURL = `https://mainnet.infura.io/v3/${INFURA_ID_PROJECT}`

module.exports = {
  networks: {
    hardhat: {
      allowUnlimitedContractSize: false,
    },
    kovan: {
      url: kovanURL,
      chainId: 42,
      gas: "auto",
      accounts: [`${ACCOUNT_SECRET_KEY}`],
      saveDeployments: true
    },
    goerli: {
      url: goerliURL,
      chainId: 5,
      gasPrice: 1000,
      accounts: [`${ACCOUNT_SECRET_KEY}`],
      saveDeployments: true
    },
    rinkeby: {
      url: rinkebyURL,
      chainId: 4,
      gasPrice: "auto",
      accounts: [`${ACCOUNT_SECRET_KEY}`],
      saveDeployments: true
    },
    mainnet: {
      url: mainnetURL,
      chainId: 1,
      gasPrice: "auto",
      accounts: [`${ACCOUNT_SECRET_KEY}`],
      saveDeployments: true
    },
    bscTestnet: {
      url: "https://data-seed-prebsc-1-s1.binance.org:8545/",
      chainId: 97,
      gasPrice: "auto",
      accounts: [`${ACCOUNT_SECRET_KEY}`],
      saveDeployments: true
    },
    bsc: {
      url: "https://bsc-dataseed.binance.org",
      chainId: 56,
      gasPrice: "auto",
      accounts: [`${ACCOUNT_SECRET_KEY}`],
      saveDeployments: true
    }
  },
  gasReporter: {
    enabled: REPORT_GAS !== undefined,
    currency: "USD"
  },
  etherscan: {
    apiKey: ETHERSCAN_API_KEY
  },
  solidity: {
    compilers: [
        {
          version: "0.8.15",
          settings: {},
          settings: {
            optimizer: {
              enabled: true,
              runs: 200,
            },
            metadata: {
              // do not include the metadata hash, since this is machine dependent
              // and we want all generated code to be deterministic
              // https://docs.soliditylang.org/en/v0.7.6/metadata.html
              bytecodeHash: "none",
            },
          },
        },
      ],
  
    
  },

  namedAccounts: {
    deployer: 0,
    },

  paths: {
    sources: "contracts",
  },
  gasReporter: {
    currency: 'USD',
    enabled: (REPORT_GAS === "true") ? true : false
  },
  mocha: {
    timeout: 200000
  }
}