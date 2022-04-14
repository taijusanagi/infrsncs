import { ethers, network } from "hardhat";

const omnichain = require("../omnichain.json");

async function main() {
  const config = omnichain[network.name];
  const ChainBeats = await ethers.getContractFactory("ChainBeats");
  const chainBeats = await ChainBeats.deploy(
    config.endpoint,
    config.gasForDestinationLzReceive,
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
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
