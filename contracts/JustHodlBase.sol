// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "@openzeppelin/contracts/GSN/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract JustHodlBase is Context, IERC20 {
    using SafeMath for uint256;
    using Address for address;

    uint256 internal _totalHodlSinceLastBuy = 0;
    uint256 internal _totalHodlersCount = 0;
    uint256 internal _bonusSupply = 0;
    uint256 internal _holdersSupply = 0;

    mapping (address => uint256) internal _hodlerHodlTime;

    mapping (address => uint256) internal _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function bonusSupply() public view returns (uint256) {
        return _bonusSupply;
    }

    function holdersSupply() public view returns (uint256) {
        return _holdersSupply;
    }

    function totalHodlSinceLastBuy() public view returns (uint256) {
        return _totalHodlSinceLastBuy;
    }

    function balanceOf(address account) public view override returns (uint256) {
        uint256 balance = _balances[account];
        if (balance > 0 && hodlMinimumAchived(account)) {
            return balance + _getHodlBonus(account, balance);
        } else {
            return balance;
        }
    }

    function pureBalanceOf(address _address) public view returns (uint256) {
        return _balances[_address];
    }

    function pureBonusOf(address _address) public view returns (uint256) {
        return balanceOf(_address).sub(_balances[_address]);
    }

    function hodlTimeOf(address _address) public view returns (uint256) {
        return _hodlerHodlTime[_address];
    }

    function hodlMinimumAchived(address _address) public view returns (bool) {
        uint256 hodlTime = _hodlerHodlTime[_address];
        return hodlTime > 0 && (now - 7 days) > hodlTime;
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "JustHodlBase: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "JustHodlBase: decreased allowance below zero"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "JustHodlBase: transfer from the zero address");
        require(recipient != address(0), "JustHodlBase: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 finalSenderAmount = amount;
        uint256 pureBalance = _balances[sender];
        uint256 totalBalance = balanceOf(sender);
        if (amount > pureBalance && amount <= totalBalance) {
            finalSenderAmount = pureBalance;
        }

        _balances[sender] = _balances[sender].sub(finalSenderAmount, "JustHodlBase: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "JustHodlBase: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _getMinHodlDiff() internal view returns (uint256) {
        return (now - 7 days);
    }

    function _getHoldDiff(address _address, uint256 _minHodlDiff) internal view returns (uint256) {
        return _minHodlDiff - _hodlerHodlTime[_address];
    }

    function _getHodlBonus(address _address, uint256 _balance) internal view returns (uint256) {
        uint256 minHodlDiff = _getMinHodlDiff();
        uint256 hodlDiff = _getHoldDiff(_address, minHodlDiff);
        uint256 totalHodlDiff = minHodlDiff.mul(_totalHodlersCount) - _totalHodlSinceLastBuy;
        return _bonusSupply.mul(((_balance*10**18).div(_holdersSupply).add((hodlDiff*10**18).div(totalHodlDiff))).div(2)).div(10**18);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "JustHodlBase: approve from the zero address");
        require(spender != address(0), "JustHodlBase: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}
