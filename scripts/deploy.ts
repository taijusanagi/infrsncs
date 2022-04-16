import { ethers, network } from "hardhat";
import * as fs from "fs";
import * as path from "path";

export const filePath = "../omnichain.json";
const omnichain = require("../omnichain.json");

async function main() {
  const config = omnichain[network.name];
  const INFRSNCS = await ethers.getContractFactory("INFRSNCS");
  const infrsnc = await INFRSNCS.deploy(
    config.endpoint,
    config.chainSeed,
    config.startTokenId,
    config.endTokenId,
    config.mintPrice
  );
  await infrsnc.deployed();
  const [signer] = await ethers.getSigners();
  await infrsnc.mint(signer.address, { value: config.mintPrice });
  await infrsnc.mint(signer.address, { value: config.mintPrice });
  await infrsnc.mint(signer.address, { value: config.mintPrice });
  omnichain[network.name].deployed = infrsnc.address;
  fs.writeFileSync(path.join(__dirname, filePath), JSON.stringify(omnichain));
  console.log("deployed:", infrsnc.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
