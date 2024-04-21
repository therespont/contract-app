require("@nomicfoundation/hardhat-ethers");
require("@oasisprotocol/sapphire-hardhat");
require("dotenv").config({ path: __dirname + "/../.env" });

module.exports = {
  solidity: "0.8.20",
  networks: {
    sapphire_testnet: {
      url: process.env.SAPPHIRE_TESTNET_ENDPOINT,
      accounts: [process.env.PRIVATE_KEY],
      chainId: 0x5aff,
    },
  },
};
