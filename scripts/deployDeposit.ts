import * as dotenv from 'dotenv'
import hre from 'hardhat'

dotenv.config()

const USDT_ADDRESS = '0x337610d27c682E347C9cD60BD4b3b107C9d34dDd' // https://testnet.bscscan.com/token/0x337610d27c682E347C9cD60BD4b3b107C9d34dDd
const VOTE_ADDRESS = '0xc704a34fa25fa9bd841a361f9879a107d6dac63e' // https://testnet.bscscan.com/token/0xc704a34fa25fa9bd841a361f9879a107d6dac63e

async function main() {
    const walletClients = await hre.viem.getWalletClients()
    if (walletClients.length === 0) {
        throw new Error('Không tìm thấy ví nào trong cấu hình Hardhat')
    }

    const walletClient = walletClients[0]
    const publicClient = await hre.viem.getPublicClient()

    const artifact = await hre.artifacts.readArtifact('VotingDeposit')
    const bytecode = artifact.bytecode as `0x${string}`
    const abi = artifact.abi

    console.log('Deploying VotingDeposit...')
    const hash = await walletClient.deployContract({
        abi,
        bytecode,
        args: [USDT_ADDRESS, VOTE_ADDRESS],
    })

    const receipt = await publicClient.waitForTransactionReceipt({ hash })
    if (receipt.contractAddress) {
        console.log(`VotingDeposit deployed at: ${receipt.contractAddress}`)
        console.log('Run the following command to verify:')
        console.log(`npx hardhat verify --network bscTestnet ${receipt.contractAddress} ${USDT_ADDRESS} ${VOTE_ADDRESS}`)
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
