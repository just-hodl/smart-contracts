const JustHodl = artifacts.require('JustHodl.sol');

module.exports = async function(deployer) {
  await deployer.deploy(JustHodl, { gas: 7000000 });
};
