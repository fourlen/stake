const { expect } = require("chai");
const { BigNumber } = require("ethers");
const { ethers } = require("hardhat");

const hund_nanotokens = BigNumber.from(100000000000n);
testERC20 = null;
stake = null;

function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

describe("Deployment, transfering tokens, approvance and testing staking", function () {


  it("Should deploy testERC20 token and Stake contract", async function () {
    const TestERC20 = await ethers.getContractFactory("testERC20");
    testERC20 = await TestERC20.deploy(10 * hund_nanotokens); //emit 1000 tokens
    await testERC20.deployed();

    console.log(`testERC20 address: ${testERC20.address}`);
    
    const Stake = await ethers.getContractFactory("Stake");
    stake = await Stake.deploy(testERC20.address, 1, 2, 3, 4, 5); // 1% for Iron, 2% for bronze, 3% for silver and etc.
    await stake.deployed();

    console.log(`Stake address: ${stake.address}`);
  });


  it(`Should transfer 100 tokens to account and make approve for stake contract`, async function () {
    const signers = await ethers.getSigners();
    
    const send_tokens = await testERC20.transfer(signers[19].address, hund_nanotokens);
    await send_tokens.wait();

    expect(await testERC20.balanceOf(signers[19].address)).to.equal(hund_nanotokens);
    const approve = await testERC20.connect(signers[19]).approve(stake.address, hund_nanotokens);
    await approve.wait();

    expect(await testERC20.allowance(signers[19].address, stake.address)).to.equal(hund_nanotokens);
    console.log(`${signers[19].address} now have 100 test tokens`);
  });


  it("Should deposit 10, 100, ... 100000 tokens wei and check levels, withdraw, than change reward percent, deposit 50 nanotokens, wait for 10 secs collect reward.", async function () {
    const signers = await ethers.getSigners();
    

    //deposit test
    const dep10 = await stake.connect(signers[19]).deposit(10);
    await dep10.wait();
    staker = await stake.stakers(signers[19].address);
    expect(staker.level).to.equal(4); //Iron

    const dep100 = await stake.connect(signers[19]).deposit(100);
    await dep100.wait();
    staker = await stake.stakers(signers[19].address);
    expect(staker.level).to.equal(3); //Bronze

    const dep1000 = await stake.connect(signers[19]).deposit(1000);
    await dep1000.wait();
    staker = await stake.stakers(signers[19].address);
    expect(staker.level).to.equal(2); //Silver

    const dep10000 = await stake.connect(signers[19]).deposit(10000);
    await dep10000.wait();
    staker = await stake.stakers(signers[19].address);
    expect(staker.level).to.equal(1); //Gold

    const dep100000 = await stake.connect(signers[19]).deposit(100000);
    await dep100000.wait();
    staker = await stake.stakers(signers[19].address);
    expect(staker.level).to.equal(0); //Platinum

    const withdraw = await stake.connect(signers[19]).withdraw(staker.amount);
    await withdraw.wait();
    expect(await testERC20.balanceOf(signers[19].address)).to.equal(hund_nanotokens); //reward is 0

    //change percent
    const change_percent = await stake.changeRewardPercent(0, 10);
    await change_percent.wait()
    expect(await stake.level_reward(0)).to.equal(10);

    const start = new Date().getTime();
    const dep50nanotokens = await stake.connect(signers[19]).deposit(hund_nanotokens / 2);
    await dep50nanotokens.wait();


    
    await sleep(10000);
    await network.provider.send("evm_mine")

  
    //collect reward test
    staker_prebalance = (await testERC20.balanceOf(signers[19].address));
    console.log(staker_prebalance);
    collectReward = await stake.connect(signers[19]).collectReward(false);
    await collectReward.wait();
    const end = new Date().getTime();
    staker = await stake.stakers(signers[19].address);
    reward = Math.floor((staker.amount * 10 * (end - start)) / (365 * 86400 * 100 * 1000));
    current_balance = await testERC20.balanceOf(signers[19].address);
    console.log(`Expexted reward: ${reward}. Actual reward: ${current_balance - staker_prebalance}`);
    expect(parseInt(current_balance)).to.lessThan(+staker_prebalance + +reward + 250);
    expect(parseInt(current_balance)).to.greaterThan(+staker_prebalance + +reward - 250);
    //can't calculate actually reward because we can't know when deposit and collectReward has executed in blockchain


  })


});
