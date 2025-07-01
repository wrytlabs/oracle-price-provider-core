import { buildModule } from '@nomicfoundation/hardhat-ignition/modules';
import { storeConstructorArgs } from '../../helper/store.args';
import { Address } from 'viem';

// config and select
export const NAME: string = 'IFALCUSDCProxyPriceAdapter'; // <-- select smart contract
export const FILE: string = 'IFALCUSDCProxyPriceAdapter'; // <-- name exported file
export const MOD: string = NAME + 'Module';
console.log(NAME);

// params
export type DeploymentParams = {
	proxy: Address;
};

export const params: DeploymentParams = {
	proxy: '0xb530a1b5259a71187f1d69acf0488f102637a3ed',
};

export type ConstructorArgs = [Address];

export const args: ConstructorArgs = [params.proxy];

console.log('Imported Params:');
console.log(params);

// export args
storeConstructorArgs(FILE, args);
console.log('Constructor Args');
console.log(args);

// fail safe
process.exit();

export default buildModule(MOD, (m) => {
	return {
		[NAME]: m.contract(NAME, args),
	};
});
