import { ethers } from "hardhat";

const tokens = (n: number) => {
  return ethers.parseUnits(n.toString(), "ether")
}

async function main() {
  const [buyer, seller, inspector, lender] = await ethers.getSigners();

  // // deploy real estate contract
  // console.log('deploying real estate contract...')
  // const RealEstate = await ethers.getContractFactory("RealEstate");
  // const realEstate = await RealEstate.deploy();
  // await realEstate.waitForDeployment();
  // console.log(`deployed real estate contract at address ${await realEstate.getAddress()}`)


  console.log('Done')
}
// run command --> npx hardhat run scripts/deploy.ts --network localhost
// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
