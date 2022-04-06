// import { expect } from "chai";
import { ethers } from "hardhat";
import * as fs from "fs";
import * as path from "path";
import { Sound } from "../typechain";

describe("Sound", function () {
  let sound: Sound;
  let signer: string;

  this.beforeEach(async function () {
    const Sound = await ethers.getContractFactory("Sound");
    sound = await Sound.deploy();
    await sound.deployed();
    [{ address: signer }] = await ethers.getSigners();
  });

  it("Should return the proper metadata", async function () {
    const mintedTokenId = 0;
    await sound.mint(signer);
    const metadata = await sound.getMetadata(mintedTokenId);
    console.log(JSON.parse(ethers.utils.toUtf8String(metadata)));
  });
});
