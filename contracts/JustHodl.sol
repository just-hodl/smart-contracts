pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./JustHodlBase.sol";

contract JustHodl is JustHodlBase {
    address owner;
    uint256 penaltyRatio = 1;
    uint256 totalHodlers = 0;
    uint256 maxSupply = 1000 * (10 ** 18);

    struct Hodler {
        address _address;
        bool exists;
    }

    mapping(uint256 => address) private hodlers;
    mapping(address => Hodler) private addressToHodler;

    modifier _onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor() public payable JustHodlBase("JustHodl", "jHODL") {
        owner = msg.sender;
        _mint(msg.sender, maxSupply);
        hodlers[totalHodlers] = owner;
        totalHodlers++;
    }

    function setOwner(address _address) public _onlyOwner {
        owner = _address;
    }

    function transfer(address _to, uint256 _value) public override returns (bool) {
        uint256 penalty = _value.mul(penaltyRatio).div(100);
        uint256 finalValue = _value.sub(penalty);
        if (super.transfer(_to, finalValue)) {
            super._penalty(msg.sender, penalty);
            if (!addressToHodler[_to].exists) {
                hodlers[totalHodlers] = _to;
                addressToHodler[_to] = Hodler(_to, true);
                totalHodlers = totalHodlers.add(1);
            }
            _rewardHodlers(msg.sender, _to, penalty);
            return true;
        }
        return false;
    }

    function transferFrom(address _from, address _to, uint256 _value) public override returns (bool) {
        uint256 penalty = _value.mul(penaltyRatio).div(100);
        uint256 finalValue = _value.sub(penalty);
        if (super.transferFrom(_from, _to, finalValue)) {
            super._penaltyFrom(_from, penalty);
            if (!addressToHodler[_to].exists) {
                hodlers[totalHodlers] = _to;
                addressToHodler[_to] = Hodler(_to, true);
                totalHodlers = totalHodlers.add(1);
            }
            _rewardHodlers(_from, _to, penalty);
            return true;
        }
        return false;
    }

    function _rewardHodlers(address _from, address _to, uint256 reward) private {
        uint256 totalBalance = 0;
        for(uint i = 0 ; i < totalHodlers; i++) {
            address hodler = hodlers[i];
            if (hodler != owner && !isContract(hodler) && hodler != _from && hodler != _to) {
                totalBalance = totalBalance.add(balanceOf(hodler));
            }
        }

        for(uint i = 0 ; i < totalHodlers; i++) {
            address hodler = hodlers[i];
            if (hodler != owner && !isContract(hodler) && hodler != _from && hodler != _to) {
                uint256 balance = balanceOf(hodler);
                if (balance > 0) {
                    _softTransfer(owner, hodler, reward.mul(balance).div(totalBalance));
                }
            }
        }
    }

    function isContract(address _address) public view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(_address)
        }
        return (size > 0);
    }
}
