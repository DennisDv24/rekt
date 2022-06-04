// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";
//import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract RektTransactionBatcher is VRFConsumerBase, Ownable, KeeperCompatibleInterface {
	
	bytes32 private _keyhash;
	uint256 private _fee;
	uint256 private _batcherFee;
	uint256 private _initialLiq;
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

	uint256 private _lastRandom;
	bool private _processingKeeper;

	constructor(
		address vrfCoordinator,
		address linkToken_,
		bytes32 keyhash_,
		uint256 fee_,
		uint256 batcherFee_,
		uint256 initialLiq_,
		address routerAddress_,
		address rektToken_,
		address wethToken_
	) VRFConsumerBase(vrfCoordinator, linkToken_) {
		_linkToken = linkToken_;
		_keyhash = keyhash_;
		_fee = fee_; // The exact link fee
		_batcherFee = batcherFee_;
		_initialLiq = initialLiq_;
		_routerAddress = routerAddress_;
		_rektToken = rektToken_;
		_wethToken = wethToken_;
		_path = [_rektToken, _wethToken];
		_linkFeePath = [_rektToken, _wethToken, _linkToken];
	}

	event Received(address, uint);
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

	event BatchCompleted(
		uint256 initialBatchAmount,
		uint256 totalBurnedAmount
	);

	event RemainingTokensBurned(
		uint256 extraBurnedAmount
	);

	function sellRektCoin(uint256 amount) public {
		require(!_processingKeeper, "REKT: There is an keep up. Wait for the next batch.");
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
		_sellSmallAmountForTheLinkFee(amount);
		requestRandomness(_keyhash, _fee); 
	}

	function _sellSmallAmountForTheLinkFee(uint256 amountToSell) private {
		uint256 currentRektFee = getCurrentRektFee();
		require(amountToSell >= currentRektFee, "REKT: You need to swap an bigger amount.");
		_fromAccToAmountSelling[msg.sender] -= currentRektFee;	
		_totalBatchAmount -= currentRektFee;

		IERC20(_rektToken).approve(_routerAddress, currentRektFee);
		IUniswapV2Router02(_routerAddress).swapTokensForExactTokens(
			_fee,
			currentRektFee,
			_linkFeePath,
			address(this),
			3281613700
		);
	}

	
	function fulfillRandomness(
		bytes32 _requestId,
		uint256 _randomness
	) internal override {
		require(_saleOfBatchInProcess, "REKT: Theres not any batch to calculate.");
		_processingKeeper = true;
		_lastRandom = _randomness;
	}
	
	function checkUpkeep(bytes calldata) external view override returns (
		bool upkeepNeeded, bytes memory
	) {
		upkeepNeeded =  _processingKeeper;
	}

	function performUpkeep(bytes calldata) external override {
		_fulfillSellOrders(_lastRandom);
		_totalBatchAmount = 0;
		_burnRemainingTokens();
		_saleOfBatchInProcess = false;
		_processingKeeper = false;
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
		emit BatchCompleted(_totalBatchAmount, amountToBurn);
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

	function _burnRemainingTokens() private {
		uint256 remainingBalance = IERC20(_rektToken).balanceOf(address(this));
		IERC20(_rektToken).transfer(_deadAddress, remainingBalance);
	}

	function fromAccToAmountSelling(address addr) public view returns (uint256) {
		return _fromAccToAmountSelling[addr];
	}

	function totalBatchAmount() public view returns (uint256) {
		return _totalBatchAmount;
	}

	function saleOfBatchInProcess() public view returns (bool) {
		return _saleOfBatchInProcess;
	}

	function getCurrentRektFee() public view returns (uint256) {
		return (
			IERC20(_rektToken).totalSupply() * _batcherFee
		) / _initialLiq;
	}

	function lastRandom() public view returns (uint256) {
		return _lastRandom;
	}

	function processingKeeper() public view returns (bool) {
		return _processingKeeper;
	}

}
