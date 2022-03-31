import { ethers } from "hardhat";

async function main() {
  const Noise = await ethers.getContractFactory("Noise");
  const noise = await Noise.deploy();
  await noise.deployed();

  const [signer] = await ethers.getSigners();
  await noise.mint(signer.address);

  console.log("Noise deployed to:", noise.address);
  console.log("Noise minted to:", signer.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
