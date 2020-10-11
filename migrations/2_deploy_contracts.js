const moment = require('moment');
const JustHodl = artifacts.require('JustHodl.sol');
const JHStakingRewardsLock = artifacts.require('JHStakingRewardsLock.sol');
const JHFutureRewardsLock = artifacts.require('JHFutureRewardsLock.sol');
const stakingRewardsReleaseTS = moment().add(14, 'days').unix();
const futureRewardsReleaseTS = moment().add(1, 'month').unix();

module.exports = async function(deployer) {
  await deployer.deploy(JustHodl, { gas: process.env.GAS_VALUE });
  const JustHodlInstance = await JustHodl.deployed();
  const owner = await JustHodlInstance.getOwner();

  await deployer.deploy(
    JHStakingRewardsLock,
    JustHodlInstance.address,
    owner,
    stakingRewardsReleaseTS,
    { gas: process.env.GAS_VALUE }
  );

  await deployer.deploy(
    JHFutureRewardsLock,
    JustHodlInstance.address,
    owner,
    futureRewardsReleaseTS,
    { gas: process.env.GAS_VALUE }
  );
};
