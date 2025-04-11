import hre from 'hardhat'
import { getContract } from 'viem'

async function main() {
    console.log('Đang triển khai VOTE...')

    const walletClients = await hre.viem.getWalletClients()
    if (walletClients.length === 0) {
        throw new Error('Không tìm thấy ví nào trong cấu hình Hardhat')
    }

    const walletClient = walletClients[0]
    const publicClient = await hre.viem.getPublicClient()

    const artifact = await hre.artifacts.readArtifact('VOTE')
    const bytecode = artifact.bytecode as `0x${string}`
    const abi = artifact.abi

    const hash = await walletClient.deployContract({
        abi,
        bytecode,
        args: [],
    })

    const receipt = await publicClient.waitForTransactionReceipt({ hash })
    if (!receipt.contractAddress) {
        throw new Error('Triển khai VOTE thất bại: Không nhận được địa chỉ contract')
    }

    console.log('VOTE deployed to:', receipt.contractAddress, receipt.transactionHash)

    // // Tạo instance contract để tương tác
    // const VOTE = getContract({
    //     abi,
    //     address: receipt.contractAddress as `0x${string}`,
    //     client: { wallet: walletClient, public: publicClient },
    // })

    // // Đọc thông tin từ contract (ví dụ: name)
    // console.log('VOTE name:', VOTE.address)
}

main().catch((error) => {
    console.error(error)
    process.exitCode = 1
})
