// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract RektTransactionBatcher is VRFConsumerBase, Ownable {
	
	bytes32 private _keyhash;
	uint256 private _fee;
	bool private _saleOfBatchInProcess;
	address payable[] private _sellersStack;

	address private _routerAddress;

	constructor(
		address vrfCoordinator,
		address linkToken,
		bytes32 keyhash_,
		uint256 fee_,
		address routerAddress_
	) VRFConsumerBase(vrfCoordinator, linkToken) {
		_keyhash = keyhash_;
		_fee = fee_;
		_routerAddress = routerAddress_;
	}
	
	address[] private _path;
	function initializePath(address tokenA, address tokenB) public onlyOwner {
		_path = [tokenA, tokenB];
	}

	function sellRektCoin(uint256 amount) public {
		if(!saleOfBatchInProcess())
			_initializeNewBatch();
		_addOrder(msg.sender, amount);
	}

	function saleOfBatchInProcess() public view returns (bool) {
		return _saleOfBatchInProcess;
	}

	function _initializeNewBatch() private {
		_saleOfBatchInProcess = true;	
		requestRandomness(_keyhash, _fee);
	}

	function fulfillRandomness(
		bytes32 _requestId,
		uint256 _randomness
	) internal override {
		require(saleOfBatchInProcess(), "REKT: Theres not any batch to calculate");
		_fulfillSellOrders(_randomness);
		_saleOfBatchInProcess = false;
	}
	
	uint256 private _totalBatchAmount = 0;
	address private _deadAddress = address(0xdead);
	mapping (address => uint256) private _fromAccToAmountSelling;

	function _fulfillSellOrders(uint256 random) private {
		uint256 amountToBurn = random % _totalBatchAmount;
		IERC20(_path[0]).transfer(_deadAddress, amountToBurn);
		_sellAtDex(_totalBatchAmount - amountToBurn);
		while(_sellersStack.length > 0) {
			address payable acc = _sellersStack[_sellersStack.length - 1];
			delete _sellersStack[_sellersStack.length - 1];
			acc.transfer((address(this).balance * _fromAccToAmountSelling[acc]) / _totalBatchAmount);
			delete _fromAccToAmountSelling[acc];
		}
		_totalBatchAmount = 0;
	}
	

	function _sellAtDex(uint256 amountToSell) private {
		IUniswapV2Router02(_routerAddress).swapExactTokensForETH(
			amountToSell,
			0,
			_path,
			address(this),
			3281613700
		);
	}

	function _addOrder(address sender, uint256 amountSelling) private {
		_fromAccToAmountSelling[sender] = amountSelling;	
		_sellersStack.push(payable(sender));
		_totalBatchAmount += amountSelling;
	}
}
