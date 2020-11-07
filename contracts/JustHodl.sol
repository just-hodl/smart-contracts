pragma solidity ^0.6.0;

import "./JustHodlBase.sol";

/*   __    __
    /  |  /  |
    $$ |  $$ |
    $$ |__$$ |
    $$    $$ |     Just Hodl
    $$$$$$$$ |     $JH
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

    mapping (address => Addr) private senderExceptions;
    mapping (address => Addr) private recipientExceptions;
    mapping (address => mapping (address => Addr)) private whitelistedSenders;

    modifier _onlyOwner() {
        require(msg.sender == owner, "JustHodl: only owner can perform this action");
        _;
    }

    constructor() public payable JustHodlBase("JustHodl", "JH") {
        owner = msg.sender;
        _mint(msg.sender, maxSupply);
    }

    function getOwner() public view returns (address) {
        return owner;
    }

    function setOwner(address _address) public _onlyOwner {
        owner = _address;
    }

    function isSenderException(address _address) public view returns (bool) {
        return senderExceptions[_address].exists;
    }

    function addSenderException(address _address) public _onlyOwner returns (bool) {
        require(!isSenderException(_address), "JustHodl: address is already present in the sender exceptions list");
        senderExceptions[_address] = Addr(_address, true);
        return true;
    }

    function removeSenderException(address _address) public _onlyOwner returns (bool) {
        require(isSenderException(_address), "JustHodl: address is not present in the sender exceptions list");
        delete senderExceptions[_address];
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
        bool isFromHodler = _isValidHodler(msg.sender);
        bool isToHodler = _isValidHodler(_to);
        if (_allowedToSend(msg.sender, _to)) {
            uint256 penalty = 0;
            uint256 finalValue = _value;
            uint256 pureFromBalanceBeforeThx = pureBalanceOf(msg.sender);
            uint256 pureToBalanceBeforeThx = pureBalanceOf(_to);
            if (isFromHodler && !hodlMinimumAchived(msg.sender)) {
                penalty = _value.mul(penaltyRatio).div(100);
                finalValue = _value.sub(penalty);
            }
            if (super.transfer(_to, finalValue)) {
                if (penalty > 0) {
                    _balances[msg.sender] = _balances[msg.sender].sub(penalty);
                }
                _updateTimer(msg.sender, _to, isFromHodler, isToHodler);
                _updateHodlersCount(msg.sender, isFromHodler, isToHodler, pureToBalanceBeforeThx);
                _updateBonusSupply(_value, penalty, pureFromBalanceBeforeThx);
                _updateHoldersSupply(isFromHodler, isToHodler, finalValue, penalty, pureFromBalanceBeforeThx);
                _updateAllowedSender(msg.sender, _to);
                return true;
            }
        }
        return false;
    }

    function transferFrom(address _from, address _to, uint256 _value) public override returns (bool) {
        bool isFromHodler = _isValidHodler(_from);
        bool isToHodler = _isValidHodler(_to);
        if (_allowedToSend(_from, _to)) {
            uint256 penalty = 0;
            uint256 finalValue = _value;
            uint256 pureFromBalanceBeforeThx = pureBalanceOf(_from);
            uint256 pureToBalanceBeforeThx = pureBalanceOf(_to);
            if (isFromHodler && !hodlMinimumAchived(_from)) {
                penalty = _value.mul(penaltyRatio).div(100);
                finalValue = _value.sub(penalty);
            }
            if (super.transferFrom(_from, _to, finalValue)) {
                if (penalty > 0) {
                    _balances[_from] = _balances[_from].sub(penalty);
                }
                _updateTimer(_from, _to, isFromHodler, isToHodler);
                _updateHodlersCount(_from, isFromHodler, isToHodler, pureToBalanceBeforeThx);
                _updateBonusSupply(_value, penalty, pureFromBalanceBeforeThx);
                _updateHoldersSupply(isFromHodler, isToHodler, finalValue, penalty, pureFromBalanceBeforeThx);
                _updateAllowedSender(_from, _to);
                return true;
            }
        }
        return false;
    }

    function _allowedToSend(address _from, address _to) private view returns (bool) {
        require (
            _from == owner ||
            _isContract(_to) ||
            isSenderException(_from) ||
            isRecipientException(_to) ||
            whitelistedSenders[_to][_from].exists,
            "JustHodl: you are not allowed to send tokens to that address"
        );
        return true;
    }

    function _updateAllowedSender(address _from, address _to) private {
        if (!whitelistedSenders[_from][_to].exists) {
            whitelistedSenders[_from][_to] = Addr(_to, true);
        }
    }

    function _updateTimer(address _from, address _to, bool _isFromHodler, bool _isToHodler) private {
        if (_isFromHodler && _balances[_from] == 0) {
            _totalHodlSinceLastBuy = _totalHodlSinceLastBuy.sub(_hodlerHodlTime[_from]);
            _hodlerHodlTime[_from] = 0;
        }
        if (_isToHodler) {
            uint256 oldLastBuy = _hodlerHodlTime[_to];
            uint256 newLastBuy = now;
            _totalHodlSinceLastBuy = _totalHodlSinceLastBuy.add(newLastBuy).sub(oldLastBuy);
            _hodlerHodlTime[_to] = newLastBuy;
        }
    }

    function _updateHodlersCount(address _from, bool _isFromHodler, bool _isToHodler, uint256 _pureToBalanceBeforeThx) private {
        if (_isFromHodler && _balances[_from] == 0) {
            _totalHodlersCount--;
        }
        if (_isToHodler && _pureToBalanceBeforeThx == 0) {
            _totalHodlersCount++;
        }
    }

    function _updateBonusSupply(uint256 _value, uint256 _penalty, uint256 _pureFromBalanceBeforeThx) private {
        if (_value > _pureFromBalanceBeforeThx) {
            uint256 spentBonus = _value.sub(_pureFromBalanceBeforeThx);
            _bonusSupply = _bonusSupply.sub(spentBonus).add(_penalty);
        } else {
            _bonusSupply = _bonusSupply.add(_penalty);
        }
    }

    function _updateHoldersSupply(bool _isFromHodler, bool _isToHodler, uint256 _value, uint256 _penalty, uint256 _pureFromBalanceBeforeThx) private {
        uint256 finalValue = _holdersSupply;
        uint256 subValue = _value;
        if (_value > _pureFromBalanceBeforeThx) {
            subValue = _pureFromBalanceBeforeThx;
        }
        if (_isFromHodler) {
            finalValue = finalValue.sub(subValue).sub(_penalty);
        }
        if (_isToHodler) {
            finalValue = finalValue.add(_value);
        }
        _holdersSupply = finalValue;
    }

    function _isValidHodler(address _address) private view returns (bool) {
        return !_isContract(_address) && _address != owner;
    }

    function _isContract(address _address) private view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(_address) }
        return size > 0;
    }
}
