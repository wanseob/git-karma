const CasperLib = artifacts.require('./Casper')
const GitKarmaToken = artifacts.require('./GitKarmaToken.sol')


module.exports = function (deployer) {
  deployer.deploy(CasperLib)
  deployer.link(CasperLib, GitKarmaToken)
  deployer.deploy(GitKarmaToken)
}
