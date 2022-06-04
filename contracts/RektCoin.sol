// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RektCoin is ERC20, Ownable {
	
	address private _poolAddress;
	address private _transactionBatcher;

	uint256 private _initialSupply;

	constructor(uint256 initialSupply_) ERC20("RektCoin2", "REKT2") {
		_initialSupply = initialSupply_;
		_mint(msg.sender, initialSupply_);
	}
	/**
	 * @dev NOTE that the function _sellingFromBather also checks
	 * if sender is doing an normal transaction
	 */
	function _transfer(
		address sender,
		address recipient,
		uint256 amount
	) internal override virtual {
		if(!_sellingFromBatcher(sender, recipient)) {
			require(
				recipient != _poolAddress,
				"REKT: You can only sell the coin using the REKTdex router"
			);
		} 
		super._transfer(sender, recipient, amount);
	}

	function _sellingFromBatcher(
		address sender,
		address recipient
	) private view returns (bool) {
		return recipient == _poolAddress && sender == _transactionBatcher;
	}

	function setPoolAddress(address poolAddress_) public onlyOwner {
		_poolAddress = poolAddress_;	
	}

	function poolAddress() public returns (address) {
		return _poolAddress;
	}

	function setTransactionBatcher(address addr) public onlyOwner {
		_transactionBatcher = addr;
	}

	function transactionBatcher() public returns (address) {
		return _transactionBatcher;
	}

	function totalSupply() public view override returns (uint256) {
		return _initialSupply - balanceOf(address(0xdead)) - balanceOf(address(0));
	}
}
