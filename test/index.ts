// import { expect } from "chai";
import { expect } from "chai";
import { ethers } from "hardhat";
import { INFRSNCS } from "../typechain";

const omnichain = require("../omnichain.json");

describe("INFRSNCS", function () {
  let infrsnc: INFRSNCS;
  let signer: string;

  const network = "ethereum_mainnet";
  const config = omnichain[network];

  this.beforeEach(async function () {
    const INFRSNCS = await ethers.getContractFactory("INFRSNCS");
    infrsnc = await INFRSNCS.deploy(
      config.endpoint,
      config.chainSeed,
      config.startTokenId,
      config.endTokenId,
      config.mintPrice
    );
    await infrsnc.deployed();
    [{ address: signer }] = await ethers.getSigners();
  });

  it("Should return the proper metadata", async function () {
    await infrsnc.mint(signer, { value: config.mintPrice });
    const tokenURI = await infrsnc.tokenURI(config.startTokenId);
    console.log(tokenURI);
  });

  it("check royalty", async function () {
    await infrsnc.mint(signer, { value: config.mintPrice });
    console.log(await infrsnc.royaltyInfo(config.startTokenId, 10000));
    await infrsnc.setRoyalty(signer, 100);
    console.log(await infrsnc.royaltyInfo(config.startTokenId, 30000));
  });
});
