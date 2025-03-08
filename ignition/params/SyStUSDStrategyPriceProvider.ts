import { Address, parseEther } from 'viem';

export type DeploymentParams = {
	proxy: Address;
	shares: bigint;
	balance: bigint;
};

export const params: DeploymentParams = {
	proxy: '0xF4030086522a5bEEa4988F8cA5B36dbC97BeE88c',
	shares: parseEther('1000'),
	balance: BigInt('5893649'),
};

export type ConstructorArgs = [Address, bigint, bigint];

export const args: ConstructorArgs = [params.proxy, params.shares, params.balance];
