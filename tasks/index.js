const omnichain = require("../omnichain.json");

task("register", "Register trusted source")
  .addParam("set", "network to register")
  .setAction(async (taskArgs) => {
    const { set } = taskArgs;
    const target = omnichain[set];
    if (!omnichain[network.name] || !target) {
      throw new Error("network invalid");
    }
    const INFRSNC = await ethers.getContractFactory("INFRSNC");
    const infrsnc = await INFRSNC.attach(omnichain[network.name].deployed);
    const tx = await infrsnc.setTrustedRemote(target.chainId, target.deployed);
    const { transactionHash } = await tx.wait();
    console.log(transactionHash);
  });

task("tokenURI", "Register trusted source")
  .addParam("token", "token")
  .setAction(async (taskArgs) => {
    const { token } = taskArgs;
    if (!omnichain[network.name]) {
      throw new Error("network invalid");
    }
    const INFRSNC = await ethers.getContractFactory("INFRSNC");
    const infrsnc = await INFRSNC.attach(omnichain[network.name].deployed);
    const tokenURI = await infrsnc.tokenURI(token);
    console.log(tokenURI);
  });
