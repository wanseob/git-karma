const chai = require('chai')
const BigNumber = web3.BigNumber
chai.use(require('chai-bignumber')(BigNumber)).should()
const Ganache = require('ganache-core')
const GitKarmaToken = artifacts.require('GitKarmaToken')
const Web3 = require('web3')
const { deployPlasmaContract } = require('./utils')

let repoIds = [
  web3.utils.sha3('repo1'),
  web3.utils.sha3('repo2')
]

String.prototype.add = function (num) {
  return this.slice(0, -2) + web3.utils.toHex(web3.utils.hexToNumber(this.slice(-2)) + num).slice(-2)
}

contract('GitKarmaToken & PlasmaContract', ([user1, user2, ...operators]) => {
  let plasmaNet
  let plasmaWeb3
  let plasmaContract
  let gitKarmaContract
  before(async () => {
    // Open plasma chain
    plasmaNet = Ganache.provider({
      logger: { log: () => {} },
      seed: 'gitkarma',
      default_balance_ether: 10000,
      gasPrice: '0x01'
    })
    plasmaWeb3 = new Web3(plasmaNet)
    plasmaContract = await deployPlasmaContract(plasmaNet, operators[0])

    // Retrieve git karma contract(anchor contract)
    gitKarmaContract = await GitKarmaToken.deployed()
  })

  // Close plasma chain
  after(async () => {
    await plasmaNet.close(() => {})
  })

  context('Casper Participation', async () => {
    it('should return added values as an array', async () => {
      await gitKarmaContract.deposit({ from: operators[0], value: web3.utils.toWei('32') })
      await gitKarmaContract.deposit({ from: operators[1], value: web3.utils.toWei('32') })
      await gitKarmaContract.deposit({ from: operators[2], value: web3.utils.toWei('32') })
      await gitKarmaContract.deposit({ from: operators[3], value: web3.utils.toWei('32') })
      await gitKarmaContract.deposit({ from: operators[4], value: web3.utils.toWei('32') })
      await gitKarmaContract.deposit({ from: operators[5], value: web3.utils.toWei('32') })
    })
    it('should register the participants as operator in the plasma chain also', async () => {
      await plasmaContract.addOperator(operators[0], { from: operators[0] })
      await plasmaContract.addOperator(operators[1], { from: operators[0] })
      await plasmaContract.addOperator(operators[2], { from: operators[0] })
      await plasmaContract.addOperator(operators[3], { from: operators[0] })
      await plasmaContract.addOperator(operators[4], { from: operators[0] })
      await plasmaContract.addOperator(operators[5], { from: operators[0] })
    })
    it('register repository', async () => {
      let multiSig1 = {}
      multiSig1.user = (await web3.eth.sign(repoIds[0], user1)).add(27)
      multiSig1.operator = (await web3.eth.sign(web3.utils.sha3(multiSig1.user), operators[0])).add(27)
      await plasmaContract.registerRepository(repoIds[0], multiSig1.user, multiSig1.operator, { from: user1 })
      let multiSig2 = {}
      multiSig2.user = (await web3.eth.sign(repoIds[1], user1)).add(27)
      multiSig2.operator = (await web3.eth.sign(web3.utils.sha3(multiSig2.user), operators[0])).add(27)
      await plasmaContract.registerRepository(repoIds[1], multiSig2.user, multiSig2.operator, { from: user1 })
    })
    it('vote', async () => {
      let users = []
      for (let i = 0; i < 100; i++) {
        let account = await plasmaWeb3.eth.personal.newAccount()
        users.push(account)
        await plasmaWeb3.eth.personal.unlockAccount(account)
        plasmaWeb3.eth.sendTransaction({
            from: operators[0],
            to: account,
            value: web3.utils.toWei('10', 'ether')
          }
        )
      }
      console.log('Transferred successfully')
      let userSig
      let operatorSig
      let anchorHash = await gitKarmaContract.anchorHash()
      let result
      for (let user of users) {
        userSig = (await plasmaWeb3.eth.sign(web3.utils.soliditySha3(repoIds[0], anchorHash), user)).add(27)
        operatorSig = (await plasmaWeb3.eth.sign(web3.utils.sha3(userSig), operators[0])).add(27)
        result = await plasmaContract.upvote(repoIds[0], anchorHash, userSig, operatorSig, { from: user })
        for (let log of result.logs) {
          if (log.event === 'Upvote') {
            console.log('upvote')
          } else if (log.event === 'Karma') {
            console.log('Karma + 1', log.args._user, log.args._totalKarma.toNumber())
          }
        }
      }
    })
    let karmaProof
    it('getKarma', async () => {
      karmaProof = await plasmaContract.getKarmaProof(user1)
      try {
        await plasmaContract.getKarmaProof(user2)
      } catch (e) {
        console.log('User2 does not have any karma')
      }
    })
    it('submitCheckpoint', async () => {
      let rootHash = await plasmaContract.getRootHash()
    })
    it('applyKarma', async () => {
      await gitKarmaContract.applyKarma(user1, karmaProof._karma, karmaProof._branchMask, karmaProof._siblings)
      console.log("Balance of user1: ", (await gitKarmaContract.balanceOf(user1)).toNumber())
    })
  })
})
