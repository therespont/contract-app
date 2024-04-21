require("@nomicfoundation/hardhat-ethers");
require("dotenv").config({path:__dirname+'/../.env'});

module.exports = {
  solidity: "0.8.20",
  networks: {
    holesky: {
      url: process.env.HOLESKY_TESTNET_ENDPOINT,
      accounts: [process.env.PRIVATE_KEY],
      chainId: 0x4268,
    },
  },
};
