// import { expect } from "chai";
import { ethers } from "hardhat";
import * as fs from "fs";
import * as path from "path";
import { ChainBeats } from "../typechain";

describe("ChainBeats", function () {
  let chainBeats: ChainBeats;
  let signer: string;

  this.beforeEach(async function () {
    const ChainBeats = await ethers.getContractFactory("ChainBeats");
    chainBeats = await ChainBeats.deploy();
    await chainBeats.deployed();
    [{ address: signer }] = await ethers.getSigners();
  });

  it("Should return the proper metadata", async function () {
    const mintedTokenId = 0;
    const mintPrice = await chainBeats.mintPrice();
    await chainBeats.mint(signer, { value: mintPrice });
    const metadata = await chainBeats.getMetadata(mintedTokenId);
    console.log(ethers.utils.toUtf8String(metadata));
  });
});
