const HodlerToken = artifacts.require('HodlerToken.sol');

module.exports = async function(deployer) {
  await deployer.deploy(HodlerToken, { gas: 7000000 });
};
