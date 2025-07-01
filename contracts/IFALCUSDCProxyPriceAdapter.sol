// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AggregatorV3LightInterface} from './interfaces/AggregatorV3LightInterface.sol';

interface IProxy {
	function convertToAssets(uint256 shares) external view returns (uint256);

	function decimals() external view returns (uint8);
}

contract IFALCUSDCProxyPriceAdapter is AggregatorV3LightInterface {
	IProxy public immutable proxy;

	constructor(address _proxy) {
		proxy = IProxy(_proxy);
	}

	function decimals() external view override returns (uint8) {
		return proxy.decimals();
	}

	function description() external pure override returns (string memory) {
		return 'iFALC/USDC proxy price oracle';
	}

	function latestRoundData()
		external
		view
		override
		returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
	{
		return (0, int256(proxy.convertToAssets(10 ** proxy.decimals())), 0, 0, 0);
	}
}
