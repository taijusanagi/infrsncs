import { ethers } from "hardhat";

async function main() {
  const ChainBeats = await ethers.getContractFactory("ChainBeats");
  const chainBeats = await ChainBeats.deploy();
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
