// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC20} from '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {AggregatorV3LightInterface} from './interfaces/AggregatorV3LightInterface.sol';

// ---------------------------------------------------------------------------------------

interface EACAggregatorProxy {
	function decimals() external view returns (uint8);

	function latestRoundData()
		external
		view
		returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

// ---------------------------------------------------------------------------------------

contract StrategyShares is ERC20 {
	address public immutable strategy;

	error NoChange();
	error NotAllowed();

	constructor(address _strategy) ERC20('Syntatic Staked BTC Hedged .70 Shares', 'SyStBTC-H.70') {
		strategy = _strategy;
	}

	function increaseShares(address to, uint256 amount) public {
		if (msg.sender != address(strategy)) revert NotAllowed();
		if (amount == 0) revert NoChange();
		_mint(to, amount);
	}

	function decreaseShares(address from, uint256 amount) public {
		if (msg.sender != address(strategy)) revert NotAllowed();
		if (amount == 0) revert NoChange();
		_burn(from, amount);
	}
}

// ---------------------------------------------------------------------------------------

contract SyStBTCH70StrategyPriceProvider is Ownable, AggregatorV3LightInterface {
	EACAggregatorProxy public immutable proxy;
	StrategyShares public immutable shares;

	uint256 public equityBalance;

	event Update(uint256 balance, uint256 shares, uint256 price);

	error NoShares();

	constructor(address _proxy, uint256 _balance) Ownable(msg.sender) {
		proxy = EACAggregatorProxy(_proxy);
		shares = new StrategyShares(address(this));
		equityBalance = _balance;

		// calc initial shares based on proxy equity price
		uint256 _shares = (_balance * equityPrice() * 1 ether) / 10 ** (2 * proxy.decimals());
		shares.increaseShares(msg.sender, _shares);
	}

	// ---------------------------------------------------------------------------------------

	function decimals() external view override returns (uint8) {
		return proxy.decimals();
	}

	function description() external pure override returns (string memory) {
		return 'SyStBTC-H.70/USD price oracle';
	}

	function equityAsset() external pure returns (string memory) {
		return 'Bitcoin';
	}

	function equitySymbol() external pure returns (string memory) {
		return 'BTC/USD';
	}

	function equityPrice() public view returns (uint256) {
		(, int256 answer, , , ) = proxy.latestRoundData();
		return uint256(answer);
	}

	function equityValue() external view returns (uint256) {
		return (equityBalance * equityPrice()) / 10 ** proxy.decimals();
	}

	// ---------------------------------------------------------------------------------------

	function setEquityBalance(uint256 _balance) external onlyOwner {
		equityBalance = _balance;
		_update();
	}

	function increaseShares(address to, uint256 _balance, uint256 _amount) external onlyOwner {
		uint256 _totalSupply = shares.totalSupply();
		uint256 _existingSharesRatio = 1 ether - (_amount * 1 ether) / _balance;
		uint256 _missingShares = (_totalSupply * 1 ether) / _existingSharesRatio - _totalSupply;
		equityBalance = _balance;

		shares.increaseShares(to, _missingShares);
		_update();
	}

	function decreaseShares(uint256 _balance, uint256 _amount) external onlyOwner {
		uint256 _removalSharesRatio = (_amount * 1 ether) / (_balance + _amount);
		uint256 _burningShares = (shares.totalSupply() * _removalSharesRatio) / 1 ether;
		equityBalance = _balance;

		shares.decreaseShares(msg.sender, _burningShares);
		_update();
	}

	function _update() internal {
		(, int256 answer, , , ) = latestRoundData();
		emit Update(equityBalance, shares.totalSupply(), uint256(answer));
	}

	// ---------------------------------------------------------------------------------------

	// Returns share price by evenly distributing total equity across all shares
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
				(equityBalance * uint256(answer) * 1 ether) / (shares.totalSupply() * 10 ** proxy.decimals())
			);
		}
	}
}
