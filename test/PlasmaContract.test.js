const chai = require('chai')
const BigNumber = web3.BigNumber
chai.use(require('chai-bignumber')(BigNumber)).should()
const PlasmaContract = artifacts.require('PlasmaContract')
chai.use(require('chai-bignumber')(BigNumber)).should()

contract('PlasmaContract', ([deployer, ...members]) => {
  let plasmaContract
  context('Test', async () => {
    beforeEach('Deploy new contract', async () => {
      plasmaContract = await PlasmaContract.new()
    })
    describe.skip('function()', async () => {
      it('should return added values as an array', async () => {
      })
    })
  })
})
