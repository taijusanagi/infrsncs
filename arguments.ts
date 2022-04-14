import { network } from "hardhat";
import { GAS_FOR_DESTINATION_LZ_RECEIVE } from "./lib/constants";
const omnichain = require("./omnichain.json");
const config = omnichain[network.name];

const args = [
  config.endpoint,
  config.startTokenId,
  config.endTokenId,
  config.mintPrice,
  GAS_FOR_DESTINATION_LZ_RECEIVE,
  config.genesisBlockHash,
];

export default args;
