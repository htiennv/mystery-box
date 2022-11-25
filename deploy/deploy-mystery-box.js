const { network, ethers } = require('hardhat')
const { verify } = require('../verify')

const { developmentChains, networkConfig } = require('../dev-hardhat-config')


module.exports = async function({ getNamedAccounts, deployments }) {
  const { deploy, log } = deployments;
  const { deployer } = await getNamedAccounts();

  const chainId = network.config.chainId;

  let price,
    subId,
    vrfCoordinatorV2Address,
    keyHash;
  if (!developmentChains.includes(network.name)) {
    price = networkConfig[chainId].price;
    subId = networkConfig[chainId].subId;
    vrfCoordinatorV2Address = networkConfig[chainId].vrfCoordinatorV2;
    keyHash = networkConfig[chainId].keyHash;
  }

  const args = [
    vrfCoordinatorV2Address,
    subId,
    keyHash,
    price,
  ]

  log('Deploying...')
  const mysteryBox = await deploy('MysteryBox', {
    from: deployer,
    args: args,
    log: true,
    waitConfirmations: network.config.blockConfirmations || 1,
  })

  // Verify contract
  if (
    !developmentChains.includes(network.name) &&
    process.env.ETHERSCAN_API_KEY
  ) {
    log('Verifying...')
    await verify(mysteryBox.address, args)
  }
}

