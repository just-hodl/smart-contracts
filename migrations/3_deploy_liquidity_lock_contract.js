const moment = require('moment');
const JustHodl = artifacts.require('JustHodl.sol');
const JHLiqTimeLock = artifacts.require('JHLiqTimeLock.sol');
const twoWeeks = moment().add(2, 'weeks').unix();

module.exports = async function(deployer) {
  const JustHodlInstance = await JustHodl.deployed();
  const owner = await JustHodlInstance.getOwner();

  await deployer.deploy(
    JHLiqTimeLock,
    JustHodlInstance.address,
    owner,
    twoWeeks
  );
};
