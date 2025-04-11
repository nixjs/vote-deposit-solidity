import type { HardhatUserConfig } from 'hardhat/config'
import '@nomicfoundation/hardhat-toolbox-viem'

import * as dotenv from 'dotenv'

dotenv.config()

const { INFURA_PROJECT_ID, PRIVATE_KEY, ETHERSCAN_API_KEY } = process.env

const config: HardhatUserConfig = {
    solidity: '0.8.28',
    networks: {
        sepolia: {
            url: `https://sepolia.infura.io/v3/${INFURA_PROJECT_ID}`,
            accounts: PRIVATE_KEY ? [PRIVATE_KEY] : [],
        },
        bscTestnet: {
            url: `https://bsc-testnet.infura.io/v3/${INFURA_PROJECT_ID}`,
            accounts: PRIVATE_KEY ? [PRIVATE_KEY] : [],
        },
    },
    etherscan: {
        apiKey: ETHERSCAN_API_KEY,
    },
}

export default config
