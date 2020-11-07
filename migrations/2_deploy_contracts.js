const moment = require('moment');
const JustHodl = artifacts.require('JustHodl.sol');
const JHTimeLock = artifacts.require('JHTimeLock.sol');
const twoWeeks = moment().add(2, 'weeks').unix();

module.exports = async function(deployer) {
  await deployer.deploy(JustHodl);
  const JustHodlInstance = await JustHodl.deployed();

  await deployer.deploy(
    JHTimeLock,
    JustHodlInstance.address,
    process.env.LOCKED_TOKENS_OWNER_1,
    twoWeeks
  );

  await deployer.deploy(
    JHTimeLock,
    JustHodlInstance.address,
    process.env.LOCKED_TOKENS_OWNER_2,
    twoWeeks
  );
};
