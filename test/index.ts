// import { expect } from "chai";
import { ethers } from "hardhat";
import * as fs from "fs";
import * as path from "path";
import { ChainBeats } from "../typechain";
import { NULL_ADDRESS, NULL_BYTES32 } from "../lib/constants";

describe("ChainBeats", function () {
  let chainBeats: ChainBeats;
  let signer: string;
  const startTokenId = 1000;
  const endTokenId = 1250;
  const mintPrice = "0";
  const gasForDestinationLzReceive = 0;
  const genesisBlockHash = NULL_BYTES32;
  this.beforeEach(async function () {
    const ChainBeats = await ethers.getContractFactory("ChainBeats");
    chainBeats = await ChainBeats.deploy(
      NULL_ADDRESS,
      gasForDestinationLzReceive,
      genesisBlockHash,
      startTokenId,
      endTokenId,
      mintPrice
    );
    await chainBeats.deployed();
    [{ address: signer }] = await ethers.getSigners();
  });

  it("Should return the proper metadata", async function () {
    await chainBeats.mint(signer, { value: mintPrice });
    const tokenURI = await chainBeats.tokenURI(startTokenId);
    // console.log(tokenURI);
  });
});
