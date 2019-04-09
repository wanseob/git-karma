const CasperLib = artifacts.require('./Casper')
const PatriciaTree = artifacts.require('./PatriciaTree')
const GitKarmaToken = artifacts.require('./GitKarmaToken.sol')


module.exports = function (deployer) {
  deployer.deploy(CasperLib)
  deployer.deploy(PatriciaTree)
  deployer.link(CasperLib, GitKarmaToken)
  deployer.link(PatriciaTree, GitKarmaToken)
  deployer.deploy(GitKarmaToken)
}
