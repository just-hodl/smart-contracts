pragma solidity ^0.6.0;

import "./JustHodlBase.sol";

/*   __    __
    /  |  /  |
    $$ |  $$ |
    $$ |__$$ |
    $$    $$ |     Just Hodl
    $$$$$$$$ |     $JHO
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
    mapping (address => Addr) private senderExceptions;
    mapping (address => Addr) private recipientExceptions;
    mapping (address => mapping (address => Addr)) private whitelistedSenders;

    modifier _onlyOwner() {
        require(msg.sender == owner, "JustHodl: only owner can perform this action");
        _;
    }

    constructor() public payable JustHodlBase("JustHodl", "JHO") {
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
        if (isPenaltyException(msg.sender) || isPenaltyException(_to)) {
            if (super.transfer(_to, _value)) {
                _updateHoldersSupply(isFromHodler, isToHodler, _value, 0);
                return true;
            }
            return false;
        } else {
            if (_allowedToSend(msg.sender, _to)) {
                uint256 penalty = 0;
                uint256 finalValue = _value;
                uint256 pureBalanceBeforeThx = pureBalanceOf(msg.sender);
                if (isFromHodler && !hodlMinimumAchived(msg.sender)) {
                    penalty = _value.mul(penaltyRatio).div(100);
                    finalValue = _value.sub(penalty);
                }
                if (super.transfer(_to, finalValue)) {
                    if (penalty > 0) {
                        _balances[msg.sender] = _balances[msg.sender].sub(penalty);
                    }
                    _updateTimer(msg.sender, _to, isFromHodler, isToHodler);
                    _updateBonusSupply(_value, penalty, pureBalanceBeforeThx);
                    _updateHoldersSupply(isFromHodler, isToHodler, finalValue, penalty);
                    _updateAllowedSender(msg.sender, _to);
                    return true;
                }
            }
            return false;
        }
    }

    function transferFrom(address _from, address _to, uint256 _value) public override returns (bool) {
        bool isFromHodler = _isValidHodler(_from);
        bool isToHodler = _isValidHodler(_to);
        if (isPenaltyException(_from) || isPenaltyException(_to)) {
            if (super.transferFrom(_from, _to, _value)) {
                _updateHoldersSupply(isFromHodler, isToHodler, _value, 0);
                return true;
            }
           return false;
        } else {
            if (_allowedToSend(_from, _to)) {
                uint256 penalty = 0;
                uint256 finalValue = _value;
                uint256 pureBalanceBeforeThx = pureBalanceOf(_from);
                if (isFromHodler && !hodlMinimumAchived(_from)) {
                    penalty = _value.mul(penaltyRatio).div(100);
                    finalValue = _value.sub(penalty);
                }
                if (super.transferFrom(_from, _to, finalValue)) {
                    if (penalty > 0) {
                        _balances[_from] = _balances[_from].sub(penalty);
                    }
                    _updateTimer(_from, _to, isFromHodler, isToHodler);
                    _updateBonusSupply(_value, penalty, pureBalanceBeforeThx);
                    _updateHoldersSupply(isFromHodler, isToHodler, finalValue, penalty);
                    _updateAllowedSender(_from, _to);
                    return true;
                }
            }
            return false;
        }
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

    function _updateHoldersSupply(bool _isFromHodler, bool _isToHodler, uint256 _value, uint256 _penalty) private {
        uint256 finalValue = _holdersSupply;
        if (_isFromHodler) {
            finalValue = finalValue.sub(_value).sub(_penalty);
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
