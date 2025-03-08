// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC20} from '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {AggregatorV3LightInterface} from './interfaces/AggregatorV3LightInterface.sol';

interface EACAggregatorProxy {
	function decimals() external view returns (uint8);

	function latestRoundData()
		external
		view
		returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

contract StrategyShares is ERC20 {
	address public immutable strategy;

	error NoChange();
	error NotAllowed();

	constructor(address _strategy) ERC20('Syntatic Staked USD via BTC Futures', 'SyStUSD') {
		strategy = _strategy;
	}

	function increaseShares(address to, uint256 amount) public {
		if (msg.sender != address(strategy)) revert NotAllowed();
		if (amount == 0) revert NoChange();
		_mint(to, amount);
	}
}

contract SyStUSDStrategyPriceProvider is Ownable, AggregatorV3LightInterface {
	EACAggregatorProxy public immutable proxy;
	StrategyShares public immutable shares;

	uint256 public latestEquityBalance;

	event Update(uint256 balance, uint256 shares, uint256 price);

	error NoShares();

	constructor(address _proxy) Ownable(msg.sender) {
		proxy = EACAggregatorProxy(_proxy);
		shares = new StrategyShares(address(this));
	}

	function decimals() external view override returns (uint8) {
		return proxy.decimals();
	}

	function description() external pure override returns (string memory) {
		return 'SyStUSD/USD price oracle';
	}

	function mint(address to, uint256 amount) external onlyOwner {
		shares.increaseShares(to, amount);
		_update();
	}

	function setEquityBalance(uint256 amount) external onlyOwner {
		latestEquityBalance = amount;
		_update();
	}

	function _update() internal {
		(, int256 answer, , , ) = latestRoundData();
		emit Update(latestEquityBalance, shares.totalSupply(), uint256(answer));
	}

	function latestRoundData()
		public
		view
		override
		returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
	{
		(roundId, answer, startedAt, updatedAt, answeredInRound) = proxy.latestRoundData();

		if (shares.totalSupply() == 0) {
			answer = int256(10 ** proxy.decimals()); // default price at 1.0
		} else {
			answer = int256(
				(latestEquityBalance * uint256(answer) * 1 ether) / (shares.totalSupply() * 10 ** proxy.decimals())
			);
		}
	}
}
