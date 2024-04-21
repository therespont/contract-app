async function main() {
  await hre.run("compile");
  const contractFactory = await hre.ethers.getContractFactory("Main", {
    libraries: {
      Cryptography: "0x6d8702A5aF67B22f09c80d1266943cca606b4e09",
    },
  });
  const contractDeploy = await contractFactory.deploy(
    "0x45aA67a07D60595a60bfB1aaF6cE359F0AC3F1dA"
  );
  console.log("Contract deployed ", contractDeploy);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
