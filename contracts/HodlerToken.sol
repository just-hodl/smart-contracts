pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract HodlerToken is ERC20Burnable {
    using SafeMath for uint256;

    address owner;
    uint256 burnRatio = 1;
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

    constructor() public payable ERC20("HodlerToken", "HODL") {
        owner = msg.sender;
        _mint(msg.sender, 100 * (10 ** 18));
        hodlers[totalHodlers] = owner;
        totalHodlers++;
    }

    function setOwner(address _address) public _onlyOwner {
        owner = _address;
    }

    function transfer(address _to, uint256 _value) public override returns (bool) {
        uint256 toBurn = _value.mul(burnRatio).div(100);
        uint256 finalValue = _value.sub(toBurn);
        if (super.transfer(_to, finalValue)) {
            super.burn(toBurn);
            if (!addressToHodler[_to].exists) {
                hodlers[totalHodlers] = _to;
                addressToHodler[_to] = Hodler(_to, true);
                totalHodlers = totalHodlers.add(1);
            }
            _rewardHodlers(msg.sender, _to);
            return true;
        }
        return false;
    }

    function transferFrom(address _from, address _to, uint256 _value) public override returns (bool) {
        uint256 toBurn = _value.mul(burnRatio).div(100);
        uint256 finalValue = _value.sub(toBurn);
        if (super.transferFrom(_from, _to, finalValue)) {
            super.burnFrom(_from, toBurn);
            if (!addressToHodler[_to].exists) {
                hodlers[totalHodlers] = _to;
                addressToHodler[_to] = Hodler(_to, true);
                totalHodlers = totalHodlers.add(1);
            }
            _rewardHodlers(_from, _to);
            return true;
        }
        return false;
    }

    function _rewardHodlers(address _from, address _to) private {
        if (maxSupply - totalSupply() > 0) {
            uint256 toMint = _valueToMint();
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
                        uint256 reward = toMint.mul(balance).div(totalBalance);
                        _mint(hodler, reward);
                    }
                }
            }
        }
    }

    function _valueToMint () public view returns (uint256) {
        uint256 remaining = maxSupply - totalSupply();
        if (remaining >= 10 ** 18) {
            return 10 ** 18;
        } else {
            return remaining;
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
