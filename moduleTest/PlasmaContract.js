const Web3 = require('web3')
const chai = require('chai')
chai.use(require('chai-bignumber')()).should()

const { PlasmaContract } = require('../build/index.tmp')
const web3Provider = new Web3.providers.HttpProvider('http://localhost:8546')
const web3 = new Web3(web3Provider)

describe(
  'Test for default settings without any cli arguments & truffle-config.js configuration',
  () => {
    let accounts
    before(async () => {
      accounts = await web3.eth.getAccounts()
      web3.eth.defaultAccount = accounts[0]
    })
    describe.skip('PlasmaContract(web3).deployed()', () => {
      it('should be able to use deployed contract', async () => {
        let plasmaContract = await PlasmaContract(web3).deployed()
      })
    })
  })
