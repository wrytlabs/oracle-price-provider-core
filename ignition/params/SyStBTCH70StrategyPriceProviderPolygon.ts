import { Address, parseEther } from 'viem';

export type DeploymentParams = {
	proxy: Address;
	balance: bigint;
};

export const params: DeploymentParams = {
	proxy: '0xc907E116054Ad103354f2D350FD2514433D57F6f',
	balance: BigInt(5893649),
};

export type ConstructorArgs = [Address, bigint];

export const args: ConstructorArgs = [params.proxy, params.balance];
