import * as dotenv from 'dotenv'
import hre from 'hardhat'

dotenv.config()

// https://testnet.bscscan.com/address/0xa1a9db6b59a4d0e8d15e29eb0cd2c698d21da35c

const USDT_ADDRESS = '0x337610d27c682E347C9cD60BD4b3b107C9d34dDd' // https://testnet.bscscan.com/token/0x337610d27c682E347C9cD60BD4b3b107C9d34dDd
const VOTE_ADDRESS = '0x8c2b774aaa86099aa6c117a569900178c4d9e120' // https://testnet.bscscan.com/token/0x8c2b774aaa86099aa6c117a569900178c4d9e120
const KYC_VERIFIER_BACKEND = '0x42Ca93Bf644dc646409637883bfcc58f24cB19e2' // Địa chỉ của backend (signer)

async function main() {
    const walletClients = await hre.viem.getWalletClients()
    if (walletClients.length === 0) {
        throw new Error('Không tìm thấy ví nào trong cấu hình Hardhat')
    }

    const walletClient = walletClients[0]
    const publicClient = await hre.viem.getPublicClient()

    const artifact = await hre.artifacts.readArtifact('VotingKYCDeposit')
    const bytecode = artifact.bytecode as `0x${string}`
    const abi = artifact.abi

    console.log('Deploying VotingKYCDeposit...')
    const hash = await walletClient.deployContract({
        abi,
        bytecode,
        args: [USDT_ADDRESS, VOTE_ADDRESS, KYC_VERIFIER_BACKEND],
    })

    const receipt = await publicClient.waitForTransactionReceipt({ hash })
    if (receipt.contractAddress) {
        console.log(`VotingKYCDeposit deployed at: ${receipt.contractAddress}`)
        console.log('Run the following command to verify:')
        console.log(
            `npx hardhat verify --network bscTestnet ${receipt.contractAddress} ${USDT_ADDRESS} ${VOTE_ADDRESS} ${KYC_VERIFIER_BACKEND}`
        )
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
