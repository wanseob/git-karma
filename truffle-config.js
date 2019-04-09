module.exports = {
  networks: {
    development: {
      host: 'localhost',
      port: 8545,
      network_id: '*' // Match any network id
    },
    test: {
      host: '127.0.0.1',
      port: 8546,
      network_id: 1234321
    }
  },
  plugins: [
    'truffle-plugin-modularizer'
  ],
  modularizer:
    {
      output: 'src/index.js',
      target: 'build/contracts',
      includeOnly: [
        'GitKarmaToken',
        'PlasmaContract'
      ], // if you don\'t configure includeOnly property, it will save all contracts
      networks: [
        1,
        2
      ] // if you don\'t configure networks property, it will save all networks
    },
  compilers: {
    solc: {
      version: '^0.5.2', // A version or constraint - Ex. "^0.5.0"
      docker: false, // Use a version obtained through docker
      settings: {
        optimizer: {
          enabled: true,
          runs: 500 // Optimize for how many times you intend to run the code
        }
      }
    }
  }
}
