// import { expect } from "chai";
import { ethers } from "hardhat";
import * as fs from "fs";
import * as path from "path";
import { INFRSNC } from "../typechain";
import { ADDRESS_1, BYTES32_1 } from "../lib/constants";

describe("INFRSNC", function () {
  let infrsnc: INFRSNC;
  let signer: string;
  const startTokenId = 1000;
  const endTokenId = 1250;
  const mintPrice = "0";
  const genesisBlockHash = BYTES32_1;
  this.beforeEach(async function () {
    const INFRSNC = await ethers.getContractFactory("INFRSNC");
    infrsnc = await INFRSNC.deploy(
      ADDRESS_1,
      genesisBlockHash,
      startTokenId,
      endTokenId,
      mintPrice
    );
    await infrsnc.deployed();
    [{ address: signer }] = await ethers.getSigners();
  });

  it("Should return the proper metadata", async function () {
    await infrsnc.mint(signer, { value: mintPrice });
    const tokenURI = await infrsnc.tokenURI(startTokenId);
    console.log(tokenURI);
  });
});
