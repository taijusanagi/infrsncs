const omnichain = require("../omnichain.json");

task("register", "Register trusted source")
  .addParam("trusted", "network to register")
  .setAction(async (taskArgs) => {
    const { trusted } = taskArgs;
    if (!omnichain[network.name] || !omnichain[trusted]) {
      throw new Error("network invalid");
    }
    const INFRSNC = await ethers.getContractFactory("INFRSNC");
    const infrsnc = await INFRSNC.attach(omnichain[network.name].deployed);
    const tx = await infrsnc.setTrustedSource(
      omnichain[trusted].chainId,
      omnichain[trusted].deployed
    );
    const { transactionHash } = await tx.wait();
    console.log(transactionHash);
  });
