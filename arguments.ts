import { network } from "hardhat";
const omnichain = require("./omnichain.json");
const config = omnichain[network.name];

const args = [
  config.endpoint,
  config.chainSeed,
  config.startTokenId,
  config.endTokenId,
  config.mintPrice,
];

export default args;
