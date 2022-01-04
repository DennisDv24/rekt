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
	
	address private _linkToken;
	address private _rektToken;
	address private _wethToken;

	uint256 private _totalBatchAmount = 0;
	address private _deadAddress = address(0xdead);
	mapping (address => uint256) private _fromAccToAmountSelling;

	address[] private _path;
	address[] private _linkFeePath;

	constructor(
		address vrfCoordinator,
		address linkToken_,
		bytes32 keyhash_,
		uint256 fee_,
		address routerAddress_,
		address rektToken_,
		address wethToken_
	) VRFConsumerBase(vrfCoordinator, linkToken_) {
		_linkToken = linkToken_;
		_keyhash = keyhash_;
		_fee = fee_;
		_routerAddress = routerAddress_;
		_rektToken = rektToken_;
		_wethToken = wethToken_;
		_path = [_rektToken, _wethToken];
		//_linkFeePath = [tokenA, tokenB, _linkToken];
	}

	event Received(address, uint);
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
	

	function sellRektCoin(uint256 amount) public {
		_addOrder(msg.sender, amount);
		if(!_saleOfBatchInProcess)
			_initializeNewBatch(amount);
	}
	function _addOrder(address sender, uint256 amountSelling) private {
		IERC20(_rektToken).transferFrom(sender, address(this), amountSelling);
		_fromAccToAmountSelling[sender] += amountSelling;	
		_sellersStack.push(payable(sender));
		_totalBatchAmount += amountSelling;
	}

	function _initializeNewBatch(uint256 amount) private {
		_saleOfBatchInProcess = true;
		//_sellSmallAmountForTheLinkFee(amount);
		requestRandomness(_keyhash, _fee);
	}
	function _sellSmallAmountForTheLinkFee(uint256 amountToSell) private {
		// TODO substract the sold amount of the msg.sender balance
		// NOTE its based on the swap, it might be variable
		// TODO test this require
		require(amountToSell >= _fee, "REKT: You need to swap an bigger amount");
		IERC20(_rektToken).approve(_routerAddress, _fee);
		IUniswapV2Router02(_routerAddress).swapTokensForExactTokens(
			_fee,
			amountToSell,
			_linkFeePath,
			address(this),
			3281613700
		);
	}

	function fulfillRandomness(
		bytes32 _requestId,
		uint256 _randomness
	) internal override {
		require(_saleOfBatchInProcess, "REKT: Theres not any batch to calculate");
		_fulfillSellOrders(_randomness);
		_totalBatchAmount = 0;
		_saleOfBatchInProcess = false;
	}
	

	function _fulfillSellOrders(uint256 random) private {
		uint256 amountToBurn = random % _totalBatchAmount;
		IERC20(_rektToken).transfer(_deadAddress, amountToBurn);
		_sellAtDex(_totalBatchAmount - amountToBurn);
		while(_sellersStack.length > 0) {
			address payable acc = _sellersStack[_sellersStack.length - 1];
			_sellersStack.pop();
			acc.transfer((address(this).balance * _fromAccToAmountSelling[acc]) / _totalBatchAmount);
			delete _fromAccToAmountSelling[acc];
		}
	}
	

	function _sellAtDex(uint256 amountToSell) private {
		IERC20(_rektToken).approve(_routerAddress, amountToSell);
		IUniswapV2Router02(_routerAddress).swapExactTokensForETH(
			amountToSell,
			0,
			_path,
			address(this),
			3281613700
		);
	}

}
