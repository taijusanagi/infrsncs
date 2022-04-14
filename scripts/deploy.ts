import { ethers, network } from "hardhat";
import { GAS_FOR_DESTINATION_LZ_RECEIVE } from "../lib/constants";

const omnichain = require("../omnichain.json");

async function main() {
  const config = omnichain[network.name];

  const ChainBeats = await ethers.getContractFactory("ChainBeats");
  const chainBeats = await ChainBeats.deploy(
    config.endpoint,
    config.startTokenId,
    config.endTokenId,
    config.mintPrice,
    GAS_FOR_DESTINATION_LZ_RECEIVE,
    config.genesisBlockHash
  );
  await chainBeats.deployed();
  const [signer] = await ethers.getSigners();
  const mintPrice = await chainBeats.mintPrice();
  await chainBeats.mint(signer.address, { value: mintPrice });
  await chainBeats.mint(signer.address, { value: mintPrice });
  await chainBeats.mint(signer.address, { value: mintPrice });
  console.log("ChainBeats deployed to:", chainBeats.address);
  console.log("ChainBeats minted to:", signer.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
