import * as dotenv from 'dotenv'
import hre from 'hardhat'

dotenv.config()

// https://testnet.bscscan.com/address/0xc2c1dfe44630411928cfafb4aaa0f33e4bb162b9#code
const VOTE_ADDRESS = '0xc704A34Fa25Fa9Bd841a361F9879A107D6DaC63e' // https://testnet.bscscan.com/token/0xc704A34Fa25Fa9Bd841a361F9879A107D6DaC63e

async function main() {
    const walletClients = await hre.viem.getWalletClients()
    if (walletClients.length === 0) {
        throw new Error('Không tìm thấy ví nào trong cấu hình Hardhat')
    }

    const walletClient = walletClients[0]
    const publicClient = await hre.viem.getPublicClient()

    const artifact = await hre.artifacts.readArtifact('TokenDeposit')
    const bytecode = artifact.bytecode as `0x${string}`
    const abi = artifact.abi

    console.log('Deploying TokenDeposit...')
    const hash = await walletClient.deployContract({
        abi,
        bytecode,
        args: [VOTE_ADDRESS],
    })

    const receipt = await publicClient.waitForTransactionReceipt({ hash })
    if (receipt.contractAddress) {
        console.log(`TokenDeposit deployed at: ${receipt.contractAddress}`)
        console.log('Run the following command to verify:')
        console.log(`npx hardhat verify --network bscTestnet ${receipt.contractAddress} ${VOTE_ADDRESS}`)
    } else {
        console.error('Deployment failed: No contract address in receipt')
    }
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error)
        process.exit(1)
    })
