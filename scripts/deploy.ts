import { ethers, network } from "hardhat";
import * as fs from "fs";
import * as path from "path";

export const filePath = "../omnichain.json";
const omnichain = require("../omnichain.json");

async function main() {
  const config = omnichain[network.name];
  const ChainBeats = await ethers.getContractFactory("ChainBeats");
  const chainBeats = await ChainBeats.deploy(
    config.endpoint,
    config.genesisBlockHash,
    config.startTokenId,
    config.endTokenId,
    config.mintPrice
  );
  await chainBeats.deployed();
  const [signer] = await ethers.getSigners();
  const mintPrice = await chainBeats.mintPrice();
  await chainBeats.mint(signer.address, { value: mintPrice });
  await chainBeats.mint(signer.address, { value: mintPrice });
  await chainBeats.mint(signer.address, { value: mintPrice });
  omnichain[network.name].deployed = chainBeats.address;
  fs.writeFileSync(path.join(__dirname, filePath), JSON.stringify(omnichain));
  console.log("deployed:", chainBeats.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
