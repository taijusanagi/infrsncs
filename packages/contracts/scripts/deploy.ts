import { ethers } from "hardhat";

async function main() {
  const Sound = await ethers.getContractFactory("Sound");
  const sound = await Sound.deploy();
  await sound.deployed();

  const [signer] = await ethers.getSigners();
  await sound.mint(signer.address);

  console.log("Sound deployed to:", sound.address);
  console.log("Sound minted to:", signer.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
