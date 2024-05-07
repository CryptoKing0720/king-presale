import { ethers } from "hardhat";

async function main() {
  const name: string = "Tether USD";
  const symbol: string = "USDT";
  const totalSupply: bigint = 1_000_000n * 10n ** 18n;
  const Token = await ethers.getContractFactory("Token");
  const token = await Token.deploy(totalSupply, name, symbol);
  await token.waitForDeployment();

  console.log("Token successfully deployed: ", token.target);

  const WETH = await ethers.getContractFactory("WETH");
  const weth = await WETH.deploy();
  await weth.waitForDeployment();

  console.log("WETH successufully deployed: ", weth.target);

  const wethContract = await ethers.getContractAt("WETH", weth.target);
  await wethContract.deposit({ value: 3_000_000_000_000_000_000n });
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
