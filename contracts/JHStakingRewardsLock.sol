pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC20/TokenTimelock.sol";

contract JHStakingRewardsLock is TokenTimelock {
    constructor(IERC20 token, address beneficiary, uint256 releaseTime)
        public
        TokenTimelock(token, beneficiary, releaseTime)
    {}
}
