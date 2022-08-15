const { expect } = require('chai');
const { ethers } = require('hardhat');

const tokens = (n) => {
  return ethers.utils.parseUnits(n.toString(), 'ether');
}

const ether = tokens;

describe('FlashLoan', () => {
  let token, flashLoanlashLoanReceiever
  let deployer

  beforeEach(async () => {
    // Setup account addresses
    accounts = await ethers.getSigners();
    deployer = accounts[0]

    // Receive contract of each contract created
    const FlashLoan = await ethers.getContractFactory('FlashLoan');
    const FlashLoanReceiver = await ethers.getContractFactory('FlashLoanReceiver');
    const Token = await ethers.getContractFactory('Token');

    // Deploy Token contract
    token = await Token.deploy("Dapp University", "DAPP", '10000000')

    // deploy FlashLoan contract
    flashLoan = await FlashLoan.deploy(token.address)

    //Approve tokens before depositing into the flashLoan pool contract
    let transaction = await token.connect(deployer).approve(flashLoan.address, tokens(10000000))
    transaction = await transaction.wait()

    //Deposit tokens into the flashLoan pool
    transaction = await flashLoan.connect(deployer).depositTokens(tokens(10000000))
    await transaction.wait()

    //Deploy FlashLoanReceiver contract
    flashLoanReceiver = await FlashLoanReceiver.deploy(flashLoan.address)
  })

  describe('Deployment', () => {
    it('Sends token to the flashloan pool contract.', async () => {
      expect(await token.balanceOf(flashLoan.address)).to.equal(tokens(10000000))
    })
  })

  describe("Borrowing funds", () => {
    it("Borrows funds from the flashloan pool contract.", async () => {
      let amount = tokens(100)
      let transaction = await flashLoanReceiver.connect(deployer).executeFlashLoan(amount);
      let result = await transaction.wait()

      await expect(transaction).to.emit(flashLoanReceiver, 'loanReceived')
        .withArgs(token.address, amount)
  })
  })
})