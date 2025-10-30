# Cronos Hardhat Boilerplate

## Hardhat dependencies (including typescript dependencies) included in this repo

This project was created with `npx hardhat init` (see hardhat.org), using Typescript.

It leverages the following libraries:

-   OpenZeppelin contracts (https://docs.openzeppelin.com/contracts/)

## Set-up

```bash
npm install
```

See the configuration file `hardhat.config.ts` including network details for Cronos blockchain.

Create .env file for environment variables, using .env.example as template.

# Create your contract(s)

Smart contracts are created in the /contracts directory.

You can use https://wizard.openzeppelin.com/ to generate standard code.

## Local deployment and testing

Compile the smart contracts:

```bash
npx hardhat compile
```

Execute the test script, and then calculate the test coverage of the smart contract code:

```bash
npx hardhat test --coverage
```

Deploy the smart contract to the local blockchain network:

```bash
npx hardhat run scripts/DeployMyERC20.script.ts --network hardhat
```

## Deployment to Cronos

Cronos Tesnet:

```bash
npx hardhat run scripts/DeployMyERC20.script.ts --network cronosTestnet
```

Cronos Mainnet:

```bash
npx hardhat run scripts/DeployMyERC20.script.ts --network cronos
```

**Alternatively**, Hardhat3 provides [hardhat ignition](https://v2.hardhat.org/ignition/docs/getting-started#overview) for easier smart contract deployment without writing traditional scripts as *scripts/DeployMyERC20.script.ts*. Kindly exec command:

```bash
npx hardhat ignition deploy ignition/modules/MyERC20.ts --network cronosTestnet
```

*Tips: Hardhat Ignition is a new declarative deployment system that provides traceable and reusable smart contract deployment workflows. It replaces traditional script-based deployments, making the process safer, more reproducible, and capable of automatically handling dependencies, parameters, and library linking.*


**Don't forget to note the address of the contract after deployment.**

## Contract verification on the block explorer

For contract verification, you need an API key for the Explorer API. Here are the URLs where you can register in order to request an API key:

-   Cronos Mainnet: https://explorer-api-doc.cronos.org/mainnet/
-   Cronos Testnet: https://explorer-api-doc.cronos.org/testnet/

Contract verification requires custom chain configuration in `hardhat.config.ts`. See the `hardhat.config.ts` file in this repository for Cronos testnet and mainnet configurations.

Verify on Cronos Testnet by including the constructor's arguments in the command line:

```shell
npx hardhat verify --network cronosTestnet "DEPLOYED_CONTRACT_ADDRESS" "Cronos Token" "CRT"
```

Of, if the constructor's arguments have been saved in the "./scripts/deploy-verification-arguments.js" file:

```bash
npx hardhat verify --network cronosTestnet "0x3F273114f20f87C602D87E1f1cd87D6F3ae5Ac72" --constructor-args "./scripts/deploy-verification-arguments.js"
```

Verify on Cronos Mainnet:

```bash
npx hardhat verify --network cronos "DEPLOYED_CONTRACT_ADDRESS" "Constructor argument 1" "Constructor argument 2"
```

**Alternatively**, for convenience, we could even complete `verify` along with deployment:

```bash
npx hardhat ignition deploy ignition/modules/MyERC20.ts --network cronosTestnet --verify                    
```