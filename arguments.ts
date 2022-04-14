import { network } from "hardhat";
const omnichain = require("./omnichain.json");
const config = omnichain[network.name];

const args = [
  config.endpoint,
  config.gasForDestinationLzReceive,
  config.genesisBlockHash,
  config.startTokenId,
  config.endTokenId,
  config.mintPrice,
];

export default args;
