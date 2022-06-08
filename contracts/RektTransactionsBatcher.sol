// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "./interfaces/IUniswapV2Router02.sol";
import "./interfaces/IUniswapV2Pair.sol";
import "./interfaces/IPegSwap.sol";

contract RektTransactionBatcher is VRFConsumerBase {
	
	bytes32 private _keyhash;
	uint256 private _linkFee;
	bool private _saleOfBatchInProcess;
	address payable[] private _sellersStack;

	address private _routerAddress;
	
	address private _bridgedLink;
	address private _wrappedLink;
	address private _pegSwap;

	address private _rektToken;
	address private _wethToken;
	address private _rektWethLPToken; 
	uint256 private _minPrice;

	uint256 private _totalBatchAmount = 0;
	address private _deadAddress = address(0xdead);
	mapping (address => uint256) private _fromAccToAmountSelling;

	address[] private _path;
	address[] private _linkFeePath;

	constructor(
		address vrfCoordinator,
		address bridgedLink_,
		address wrappedLink_,
		address pegSwap_,
		bytes32 keyhash_,
		uint256 linkFee_,
		address routerAddress_,
		address rektToken_,
		address wethToken_,
		address rektWethLPToken_,
		uint256 minPrice_
	) VRFConsumerBase(vrfCoordinator, wrappedLink_) {
		_bridgedLink = bridgedLink_;
		_wrappedLink = wrappedLink_;
		_pegSwap = pegSwap_;
		_keyhash = keyhash_;
		_linkFee = linkFee_;

		_routerAddress = routerAddress_;
		_rektToken = rektToken_;
		_wethToken = wethToken_;
		_path = [_rektToken, _wethToken];
		_linkFeePath = [_rektToken, _wethToken, _bridgedLink];
		_rektWethLPToken = rektWethLPToken_;
		_minPrice = minPrice_;
	}

	event Received(address, uint);
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

	event BatchCompleted(
		uint256 initialBatchAmount,
		uint256 totalBurnedAmount
	);

	function sellRektCoin(uint256 amount) public {
		require(amount >= getCurrentRektFee(), "REKT: getCurrentRektFee() > amountToSell");
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
		requestRandomness(_keyhash, _linkFee); 
	}

	function _sellSmallAmountForTheLinkFee(uint256 amountToSell) private {
		uint256 currentRektFee = getCurrentRektFee();
		_fromAccToAmountSelling[msg.sender] -= currentRektFee;	
		_totalBatchAmount -= currentRektFee;

		IERC20(_rektToken).approve(_routerAddress, currentRektFee);
		IUniswapV2Router02(_routerAddress).swapTokensForExactTokens(
			_linkFee,
			currentRektFee,
			_linkFeePath,
			address(this),
			3281613700
		);
		IERC20(_bridgedLink).approve(_pegSwap, _linkFee);
		IPegSwap(_pegSwap).swap(
			_linkFee,
			_bridgedLink,
			_wrappedLink
		);
	}
	
	// NOTE that the resultant fee must be always greater than the chainlink VRF fee
	function getCurrentRektFee() public view returns (uint256) {
		uint256 wethPoolBal; uint256 rektPoolBal;
		if(IUniswapV2Pair(_rektWethLPToken).token0() == _wethToken)
			(wethPoolBal, rektPoolBal, ) = IUniswapV2Pair(_rektWethLPToken).getReserves();
		else
			(rektPoolBal, wethPoolBal, ) = IUniswapV2Pair(_rektWethLPToken).getReserves();
		return (rektPoolBal / wethPoolBal) * _minPrice;
	}
	
	function fulfillRandomness(
		bytes32 _requestId,
		uint256 _randomness
	) internal override {
		if(_totalBatchAmount > 0)
			_fulfillSellOrders(_randomness);
		else emit BatchCompleted(0, 0);
		_totalBatchAmount = 0;
		_saleOfBatchInProcess = false;
		_burnRemainingTokens();
	}
	
	function _fulfillSellOrders(uint256 random) private {
		uint256 amountToBurn = random % _totalBatchAmount;
		IERC20(_rektToken).transfer(_deadAddress, amountToBurn);
		_sellAtDex(_totalBatchAmount - amountToBurn);
		uint256 thisBalance = address(this).balance;
		while(_sellersStack.length > 0) {
			address payable acc = _sellersStack[_sellersStack.length - 1];
			_sellersStack.pop();
			acc.transfer((thisBalance * _fromAccToAmountSelling[acc]) / _totalBatchAmount);
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
	
	function getRektWethLP() public view returns (address){
		return _rektWethLPToken;
	}

}
