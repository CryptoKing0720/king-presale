import { ethers } from "hardhat";

async function main() {
  const name: string = "Tether USD";
  const symbol: string = "USDT";
  const totalSupply: bigint = 1_000_000n * 10n ** 6n;
  const Token = await ethers.getContractFactory("Token");
  const token = await Token.deploy(totalSupply, name, symbol);
  await token.waitForDeployment();

  console.log("Token successfully deployed: ", token.target);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
