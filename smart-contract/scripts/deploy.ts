import { ethers } from "hardhat";

const verify = async (address: string, parameter: any[] = []) => {
  console.log(`Veryfing ${address} ...`);
  await run("verify:verify", {
    address: address,
    constructorArguments: parameter,
  });
  console.log("Success!");
};

async function main() {
  const name: string = "Tether USD";
  const symbol: string = "USDT";
  const totalSupply: bigint = 1_000_000n * 10n ** 18n;
  const Token = await ethers.getContractFactory("Token");
  const token = await Token.deploy(totalSupply, name, symbol);
  await token.waitForDeployment();

  console.log("Token successfully deployed: ", token.target);
  await verify("0x3B0b1e1d718059C45A02983792fBD2585c3d74cC", [
    totalSupply,
    name,
    symbol,
  ]);

  // const WETH = await ethers.getContractFactory("WETH");
  // const weth = await WETH.deploy();
  // await weth.waitForDeployment();

  // console.log("WETH successufully deployed: ", weth.target);

  // await verify(weth.target.toString());
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
