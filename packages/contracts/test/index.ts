import { expect } from "chai";
import { ethers } from "hardhat";

import { Noise } from "../typechain";

describe("Noise", function () {
  let noise: Noise;
  let signer: string;

  this.beforeEach(async function () {
    const Noise = await ethers.getContractFactory("Noise");
    noise = await Noise.deploy();
    await noise.deployed();
    [{ address: signer }] = await ethers.getSigners();
  });

  it("Should return the proper html", async function () {
    await noise.mint(signer);
    const html = await noise.getHTML();
    expect(html).to.equal(
      '<!DOCTYPE html><html lang="en"><head></head><body><script>console.log("a");</script><h1>Test</h1></body></html>'
    );
  });

  it("Should return the proper metadata", async function () {
    const mintedTokenId = 0;
    await noise.mint(signer);
    const metadata = await noise.getMetadata(mintedTokenId, "<html />");

    expect(ethers.utils.toUtf8String(metadata)).to.equal(
      '{"name": "Noise #0", "description": "A unique piece of noise represented entirely on-chain.","animation_url":"data:text/html <html />"}'
    );
  });
});
