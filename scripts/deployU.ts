import hre from 'hardhat'

// https://testnet.bscscan.com/address/0xe1fae36f53cd00a3bcd9ff107b6b05d5ad11dbdf

async function main() {
    console.log('Đang triển khai U...')

    const walletClients = await hre.viem.getWalletClients()
    if (walletClients.length === 0) {
        throw new Error('Không tìm thấy ví nào trong cấu hình Hardhat')
    }

    const walletClient = walletClients[0]
    const publicClient = await hre.viem.getPublicClient()

    const artifact = await hre.artifacts.readArtifact('U')
    const bytecode = artifact.bytecode as `0x${string}`
    const abi = artifact.abi

    const hash = await walletClient.deployContract({
        abi,
        bytecode,
        args: [],
    })

    const receipt = await publicClient.waitForTransactionReceipt({ hash })
    if (!receipt.contractAddress) {
        throw new Error('Triển khai U thất bại: Không nhận được địa chỉ contract')
    }

    console.log('U deployed to:', receipt.contractAddress, receipt.transactionHash)
}

main().catch((error) => {
    console.error(error)
    process.exitCode = 1
})
