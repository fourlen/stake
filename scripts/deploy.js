const hre = require("hardhat");


const {
  AMOUNT,
  IronPercent,
  BronzePercent,
  SilverPercent,
  GoldPercent,
  PlatinumPercent
} = process.env;

async function main() {

  const TestERC20 = await hre.ethers.getContractFactory("testERC20");
  const testERC20 = await TestERC20.deploy(AMOUNT);
  await testERC20.deployed();
  console.log("Token deployed to: ", testERC20.address)


  const Stake = await hre.ethers.getContractFactory("Stake");
  const stake = await Stake.deploy(testERC20.address,
    IronPercent,
    BronzePercent,
    SilverPercent,
    GoldPercent,
    PlatinumPercent);
  await stake.deployed();
  console.log("Stake deployed to: ", stake.address);

  try {
    verifyTestERC20(testERC20, AMOUNT);
    console.log("Verify testERC20 succees");
  }
  catch {
    console.log("Verify testERC20 failed");
  }
  try {
    verifyStake(stake,
        IronPercent,
        BronzePercent,
        SilverPercent,
        GoldPercent,
        PlatinumPercent);
    console.log("Verify stake success");
  }
  catch {
    console.log("Verify stae failed");
  }
}

async function verifyTestERC20(testERC20, AMOUNT) {
  await hre.run("verify:verify", {
    address: testERC20.address,
    constructorArguments: [
      AMOUNT
    ]
  })
}

async function verifyStake(stake,
    IronPercent,
    BronzePercent,
    SilverPercent,
    GoldPercent,
    PlatinumPercent) {
  await hre.run("verify:verify", {
    address: stake.address,
    constructorArguments: [
        IronPercent,
        BronzePercent,
        SilverPercent,
        GoldPercent,
        PlatinumPercent
    ]
  })
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });