import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export default buildModule("MyERC20Module", (m) => {
    const myERC20 = m.contract("MyERC20", ["Cronos Token", "CRT"]);

    return { myERC20 };
});