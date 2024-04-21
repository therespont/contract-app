async function main() {
  await hre.run("compile");
  const contractFactory = await hre.ethers.getContractFactory("Main");
  const contractDeploy = await contractFactory.deploy(
    "0x33779FCAeb2978621b276B4C059c2B29971cE0e2"
  );
  console.log("Contract deployed ", contractDeploy);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
