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
  const weth: string = "0x94373a4919B3240D86eA41593D5eBa789FEF3848";
  const pancakeRouter: string = "0x7013DC9544b461dd597FaC8dCecD41A79D143327";
  const token: string = "0x3B0b1e1d718059C45A02983792fBD2585c3d74cC";
  const PreSale = await ethers.getContractFactory("PreSale");
  const option = {
    tokenDeposit: ethers.parseUnits("10000", 18),
    hardCap: ethers.parseUnits("0.1", 18),
    softCap: ethers.parseUnits("0.05", 18),
    max: ethers.parseUnits("0.1", 18),
    min: ethers.parseUnits("0.05", 18),
    start: 1715130458,
    end: 1715230458,
    liquidityBps: 5000,
  };

  const presale = await PreSale.deploy(weth, token, pancakeRouter, option);
  await presale.waitForDeployment();

  console.log("PreSale successfully deployed: ", presale.target);

  await verify(presale.target.toString(), [weth, token, pancakeRouter, option]);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
