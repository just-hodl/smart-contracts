pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./JustHodlBase.sol";

contract JustHodl is JustHodlBase {
    address private owner;
    uint256 private penaltyRatio = 1;
    uint256 private totalHodlers = 0;
    uint256 private maxSupply = 1000 * (10 ** 18);

    struct Hodler {
        address _address;
        bool exists;
    }

    mapping(uint256 => address) private hodlers;
    mapping(address => Hodler) private addressToHodler;
    mapping(address => Hodler) private penaltyExceptions;

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

    function getOwner() public view returns (address) {
        return owner;
    }

    function setOwner(address _address) public _onlyOwner {
        owner = _address;
    }

    function isPenaltyException(address _address) public view returns (bool) {
        return penaltyExceptions[_address].exists;
    }

    function addPenaltyException(address _address) public _onlyOwner returns (bool) {
        require(!isPenaltyException(_address), "JustHodl: address is already present in the penalty exceptions list");
        penaltyExceptions[_address] = Hodler(_address, true);
        return true;
    }

    function removePenaltyException(address _address) public _onlyOwner returns (bool) {
        require(isPenaltyException(_address), "JustHodl: address is not present in the penalty exceptions list");
        delete penaltyExceptions[_address];
        return true;
    }

    function transfer(address _to, uint256 _value) public override returns (bool) {
        if (isPenaltyException(msg.sender) || isPenaltyException(_to)) {
            return super.transfer(_to, _value);
        } else {
            uint256 penalty = _value.mul(penaltyRatio).div(100);
            uint256 finalValue = _value.sub(penalty);
            if (super.transfer(_to, finalValue)) {
                super._penalty(msg.sender, penalty);
                _updateHodlers(_to);
                _rewardHodlers(msg.sender, _to, penalty);
                return true;
            }
            return false;
        }
    }

    function transferFrom(address _from, address _to, uint256 _value) public override returns (bool) {
        if (isPenaltyException(_from) || isPenaltyException(_to)) {
            return super.transferFrom(_from, _to, _value);
        } else {
            uint256 penalty = _value.mul(penaltyRatio).div(100);
            uint256 finalValue = _value.sub(penalty);
            if (super.transferFrom(_from, _to, finalValue)) {
                super._penaltyFrom(_from, penalty);
                _updateHodlers(_to);
                _rewardHodlers(_from, _to, penalty);
                return true;
            }
            return false;
        }
    }

    function _updateHodlers(address _to) private {
        if (!addressToHodler[_to].exists) {
            hodlers[totalHodlers] = _to;
            addressToHodler[_to] = Hodler(_to, true);
            totalHodlers = totalHodlers.add(1);
        }
    }

    function _rewardHodlers(address _from, address _to, uint256 reward) private {
        uint256 totalBalance = 0;
        for(uint i = 0 ; i < totalHodlers; i++) {
            address hodler = hodlers[i];
            if (_isValidHodler(hodler, _from, _to)) {
                totalBalance = totalBalance.add(balanceOf(hodler));
            }
        }

        for(uint i = 0 ; i < totalHodlers; i++) {
            address hodler = hodlers[i];
            if (_isValidHodler(hodler, _from, _to)) {
                uint256 balance = balanceOf(hodler);
                if (balance > 0) {
                    _softTransfer(owner, hodler, reward.mul(balance).div(totalBalance));
                }
            }
        }
    }

    function _isValidHodler(address _hodler, address _from, address _to) private view returns (bool) {
        return !_isContract(_hodler) && _hodler != owner && _hodler != _from && _hodler != _to;  
    }

    function _isContract(address _address) private view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(_address)
        }
        return (size > 0);
    }
}
