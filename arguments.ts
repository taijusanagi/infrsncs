import { network } from "hardhat";
import { GAS_FOR_DESTINATION_LZ_RECEIVE } from "./lib/constants";
const omnichain = require("./omnichain.json");
const config = omnichain[network.name];

const args = [
  config.endpoint,
  GAS_FOR_DESTINATION_LZ_RECEIVE,
  config.genesisBlockHash,
  config.startTokenId,
  config.endTokenId,
  config.mintPrice,
];

export default args;
