const path = require('path');
const HDWalllet = require('@truffle/hdwallet-provider');
const Web3 = require('web3');
const web3 = new Web3();

module.exports = {
  // See <http://truffleframework.com/docs/advanced/configuration>
  // to customize your Truffle configuration!
  contracts_build_directory: path.join(__dirname, './build'),
  networks: {
    develop: {
      host: 'localhost',
      port: 7545,
      network_id: '5777'
    },
    ropsten: {
      provider: function() {
        return new HDWalllet(process.env.MNEMONIC, `https://ropsten.infura.io/v3/${process.env.INFURA_ID}`, 0)
      },
      network_id: 3,
      gas: 5000000,
      gasPrice: 25000000000,
      skipDryRun: true
    },
    mainnet: {
      provider: function () {
        return new HDWalllet(process.env.MNEMONIC, `https://mainnet.infura.io/v3/${process.env.INFURA_ID}`)
      },
      network_id: 1,
      gasPrice: web3.utils.toWei('50', 'gwei'),
      skipDryRun: true
    }
  },
  compilers: {
    solc: {
      version: '0.6.6'
    }
  }
};
