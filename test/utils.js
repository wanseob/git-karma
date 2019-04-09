const PlasmaContract = artifacts.require('PlasmaContract')
const BloomFilter = artifacts.require('BloomFilter')
const PatriciaTree = artifacts.require('PatriciaTree')
const ECDSA = artifacts.require('ECDSA')

const deployPlasmaContract = async (provider, deployer) => {
  const Plasma = (contract) => {
    contract.setProvider(provider)
    return contract
  }
  // Deploy plasma contract

  let libBloomFilter = await Plasma(BloomFilter).new()
  let libPatriciaTree = await Plasma(PatriciaTree).new()
  let libECDSA = await Plasma(ECDSA).new()
  PlasmaContract.setProvider(provider)
  await PlasmaContract.link('BloomFilter', libBloomFilter.address)
  await PlasmaContract.link('PatriciaTree', libPatriciaTree.address)
  await PlasmaContract.link('ECDSA', libECDSA.address)
  let plasmaContract = await PlasmaContract.new({ from: deployer })
  return plasmaContract
}

module.exports = {
  deployPlasmaContract
}
