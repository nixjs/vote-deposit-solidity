import * as dotenv from 'dotenv'
import hre from 'hardhat'

dotenv.config()

// https://testnet.bscscan.com/address/0x2ee17c196ea9aa67c16007213c4cddf3f1222490#code
const USDT_ADDRESS = '0x337610d27c682E347C9cD60BD4b3b107C9d34dDd' // https://testnet.bscscan.com/token/0x337610d27c682E347C9cD60BD4b3b107C9d34dDd

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
        args: [USDT_ADDRESS],
    })

    const receipt = await publicClient.waitForTransactionReceipt({ hash })
    if (receipt.contractAddress) {
        console.log(`TokenDeposit deployed at: ${receipt.contractAddress}`)
        console.log('Run the following command to verify:')
        console.log(`npx hardhat verify --network bscTestnet ${receipt.contractAddress} ${USDT_ADDRESS}`)
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
