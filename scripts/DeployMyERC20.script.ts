// To run the script
// npx hardhat run scripts/DeployMyERC20.script.ts --network [network name]

import hre from "hardhat";

const { ethers } = await hre.network.connect();

const contractName = "MyERC20";

async function main() {

    const accounts = await ethers.getSigners();

    console.log(
        "Accounts:",
        accounts.map((a) => a.address)
    );

    const myContract = await ethers.getContractFactory(contractName);
    const contractInstance = await myContract.deploy(
        "Cronos Token", "CRT"
    );

    await contractInstance.waitForDeployment();
    const tx = contractInstance.deploymentTransaction();

    console.log(
        contractName,
        "contract deployed to:",
        await contractInstance.getAddress()
    );
    if (tx) {
        console.log("with transaction hash", tx.hash);
    }
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
