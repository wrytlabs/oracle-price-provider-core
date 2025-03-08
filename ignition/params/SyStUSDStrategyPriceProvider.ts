import { Address } from 'viem';

export type DeploymentParams = {
	proxy: Address;
};

export const params: DeploymentParams = {
	proxy: '0xF4030086522a5bEEa4988F8cA5B36dbC97BeE88c',
};

export type ConstructorArgs = [Address];

export const args: ConstructorArgs = [params.proxy];
