pragma solidity ^0.6.0;

import "./JustHodlBase.sol";

/*   __    __
    /  |  /  |
    $$ |  $$ |
    $$ |__$$ |
    $$    $$ |     Just Hodl
    $$$$$$$$ |     $JHODL
    $$ |  $$ |
    $$ |  $$ |
    $$ /  $$ /

    The Token For The Hodlers.

    More informations at https://justhodl.finance
*/

contract JustHodl is JustHodlBase {
    address private owner;
    uint256 private penaltyRatio = 10;
    uint256 private maxSupply = 1000 * (10 ** 18);

    struct Addr {
        address _address;
        bool exists;
    }

    mapping (address => Addr) private penaltyExceptions;
    mapping (address => Addr) private recipientExceptions;
    mapping (address => mapping (address => Addr)) private whitelistedSenders;

    modifier _onlyOwner() {
        require(msg.sender == owner, "JustHodl: only owner can perform this action");
        _;
    }

    constructor() public payable JustHodlBase("JustHodl", "JHODL") {
        owner = msg.sender;
        _mint(msg.sender, maxSupply);
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
        penaltyExceptions[_address] = Addr(_address, true);
        return true;
    }

    function removePenaltyException(address _address) public _onlyOwner returns (bool) {
        require(isPenaltyException(_address), "JustHodl: address is not present in the penalty exceptions list");
        delete penaltyExceptions[_address];
        return true;
    }

    function isRecipientException(address _address) public view returns (bool) {
        return recipientExceptions[_address].exists;
    }

    function addRecipientException(address _address) public _onlyOwner returns (bool) {
        require(!isRecipientException(_address), "JustHodl: address is already present in the recipient exceptions list");
        recipientExceptions[_address] = Addr(_address, true);
        return true;
    }

    function removeRecipientException(address _address) public _onlyOwner returns (bool) {
        require(isRecipientException(_address), "JustHodl: address is not present in the recipient exceptions list");
        delete recipientExceptions[_address];
        return true;
    }

    function isWhitelistedSender(address _address) public view returns (bool) {
        return whitelistedSenders[msg.sender][_address].exists;
    }

    function addWhitelistedSender(address _address) public returns (bool) {
        require(!isWhitelistedSender(_address), "JustHodl: address is already present in the whitelist");
        whitelistedSenders[msg.sender][_address] = Addr(_address, true);
        return true;
    }

    function removeWhitelistedSender(address _address) public returns (bool) {
        require(isWhitelistedSender(_address), "JustHodl: address is not present in the whitelist");
        delete whitelistedSenders[msg.sender][_address];
        return true;
    }

    function transfer(address _to, uint256 _value) public override returns (bool) {
        if (isPenaltyException(msg.sender) || isPenaltyException(_to)) {
            return super.transfer(_to, _value);
        } else {
            if (_allowedToSend(msg.sender, _to)) {
                uint256 penalty = 0;
                uint256 finalValue = _value;
                uint256 pureBalanceBeforeThx = pureBalanceOf(msg.sender);
                if (!_isContract(msg.sender) && !_hodlMinimumAchived(msg.sender)) {
                    penalty = _value.mul(penaltyRatio).div(100);
                    finalValue = _value.sub(penalty);
                }
                if (super.transfer(_to, finalValue)) {
                    _updateTimer(_to);
                    _updateBonusSupply(_value, penalty, pureBalanceBeforeThx);
                    return true;
                }
            }
            return false;
        }
    }

    function transferFrom(address _from, address _to, uint256 _value) public override returns (bool) {
        if (isPenaltyException(_from) || isPenaltyException(_to)) {
            return super.transferFrom(_from, _to, _value);
        } else {
            if (_allowedToSend(_from, _to)) {
                uint256 penalty = 0;
                uint256 finalValue = _value;
                uint256 pureBalanceBeforeThx = pureBalanceOf(_from);
                if (!_isContract(_from) && !_hodlMinimumAchived(_from)) {
                    penalty = _value.mul(penaltyRatio).div(100);
                    finalValue = _value.sub(penalty);
                }
                if (super.transferFrom(_from, _to, finalValue)) {
                    _updateTimer(_to);
                    _updateBonusSupply(_value, penalty, pureBalanceBeforeThx);
                    return true;
                }
            }
            return false;
        }
    }

    function _allowedToSend(address _from, address _to) private view returns (bool) {
        require (
            isRecipientException(_to) || whitelistedSenders[_to][_from].exists,
            "JustHodl: you are not allowed to send tokens to that address"
        );
        return true;
    }

    function _updateTimer(address _to) private {
        if (!_isContract(_to)) {
            uint256 oldLastBuy = _hodlerHodlTime[_to];
            uint256 newLastBuy = now;
            _totalHodlSinceLastBuy = _totalHodlSinceLastBuy.sub(oldLastBuy).add(newLastBuy);
            _hodlerHodlTime[_to] = newLastBuy;
        }
    }

    function _updateBonusSupply(uint256 _value, uint256 _penalty, uint256 _pureBalanceBeforeThx) private {
        if (_value > _pureBalanceBeforeThx) {
            uint256 spentBonus = _value.sub(_pureBalanceBeforeThx);
            _bonusSupply = _bonusSupply.sub(spentBonus).add(_penalty);
        } else {
            _bonusSupply = _bonusSupply.add(_penalty);
        }
    }

    function _isContract(address _address) private view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(_address)
        }
        return (size > 0);
    }
}
