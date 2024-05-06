import { ethers } from "hardhat";

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);

  const KingToken = await ethers.getContractFactory("KingToken");
  const contract = await KingToken.deploy("Tether USD", "USDT", 1_000_000n, 6);

  console.log("Contract deployed at: ", contract.target);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
