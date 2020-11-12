pragma solidity ^0.6.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/TokenTimelock.sol";

contract JHLiqTimeLock is TokenTimelock {
    constructor(IERC20 token, address beneficiary, uint256 releaseTime)
        public
        TokenTimelock(token, beneficiary, releaseTime)
    {}
}
