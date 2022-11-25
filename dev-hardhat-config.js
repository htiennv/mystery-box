const networkConfig = {
    5: {
      name: 'goerli',
      vrfCoordinatorV2: '0x2Ca8E0C643bDe4C2E08ab1fA0da3401AdAD7734D',
      keyHash:
        '0x79d3d8832d904592c0bf9818b621522c988bb8b0c05cdc3b15aea1b6e8db0c15',
      price: '10000000000000000', // 0.01 ETH
      subId: '6866',
    },
  }
  
  const developmentChains = ['hardhat', 'localhost']
  
  module.exports = {
    networkConfig,
    developmentChains,
  }
  