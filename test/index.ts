// import { expect } from "chai";
import { ethers } from "hardhat";
import * as fs from "fs";
import * as path from "path";
import { ChainBeats } from "../typechain";
import { NULL_ADDRESS } from "../lib/constants";

describe("ChainBeats", function () {
  let chainBeats: ChainBeats;
  let signer: string;

  const startTokenId = 10000;
  const endTokenId = 10100;
  const mintPrice = "0";

  this.beforeEach(async function () {
    const ChainBeats = await ethers.getContractFactory("ChainBeats");
    chainBeats = await ChainBeats.deploy(
      NULL_ADDRESS,
      startTokenId,
      endTokenId,
      mintPrice
    );
    await chainBeats.deployed();
    [{ address: signer }] = await ethers.getSigners();
  });

  it("Should return the proper metadata", async function () {
    await chainBeats.mint(signer, { value: mintPrice });
    const metadata = await chainBeats.getMetadata(startTokenId);
    console.log(metadata);
  });
});
