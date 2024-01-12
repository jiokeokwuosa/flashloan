import {
  loadFixture,
} from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";

const tokens = (n: number) => {
  return ethers.parseUnits(n.toString(), "ether")
}

describe("FlashLoan", function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  async function deployEscrowFixture() {
    // deploy real estate contract
    const [deployer] = await ethers.getSigners();

    const FlashLoan = await ethers.getContractFactory("FlashLoan");
    const Token = await ethers.getContractFactory("Token");

    // deploy token
    const token = await Token.deploy('CJ Token', 'CJ', tokens(1000000));
    await token.waitForDeployment()

    // deploy flash loan
    const flashLoan = await FlashLoan.deploy(token.getAddress());
    await flashLoan.waitForDeployment();

    // approve flash loans
    let transaction = await token.connect(deployer).approve(flashLoan.getAddress(), tokens(1000000))
    await transaction.wait()

    // deposit flash loans
     transaction = await flashLoan.connect(deployer).depositToken(tokens(1000000))
    await transaction.wait()

    // deploy flash loans receiver
    const FlashLoanReceiver = await ethers.getContractFactory("FlashLoanReceiver");
    const flashLoanReceiver =  await FlashLoanReceiver.deploy(flashLoan.getAddress())
    await flashLoanReceiver.waitForDeployment()

    return { deployer, flashLoan, token, flashLoanReceiver };
  }

  describe("Deployment", function () {
    it("sends correct amount of token to the flash loan contract", async function () {
      const { flashLoan, token } = await loadFixture(deployEscrowFixture);

      expect(await token.balanceOf(flashLoan.getAddress())).to.equal(tokens(1000000));
    });
  });

  describe("Borrowing funds", function () {
    it("borrows funds from the pool", async function () {
      const { flashLoanReceiver, deployer, token } = await loadFixture(deployEscrowFixture);
      let amount = tokens(100)
      let transaction = await flashLoanReceiver.connect(deployer).executeFlashLoan(amount);
      transaction.wait();

      expect(transaction).to.emit(flashLoanReceiver, 'LoanReceived').withArgs(token.getAddress(), amount)
    });
  });

});
