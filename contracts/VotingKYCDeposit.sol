// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

contract VotingKYCDeposit is Ownable, ReentrancyGuard, Pausable, EIP712 {
    using ECDSA for bytes32;

    IERC20 public immutable usdtToken;
    IERC20 public immutable voteToken;
    address public kycVerifier;

    uint256 public constant VOTE_PER_USDT = 300 * 10**18;

    mapping(address => uint256) private userDeposits;
    mapping(address => uint256) private pendingVotes;
    mapping(address => bool) public hasKycVerified;

    struct KycVerification {
        address user;
        uint256 deadline;
    }

    bytes32 private constant KYC_VERIFICATION_TYPEHASH = keccak256(
        "KycVerification(address user,uint256 deadline)"
    );

    event Deposited(address indexed user, uint256 usdtAmount, uint256 voteAmount);
    event VotesClaimed(address indexed user, uint256 voteAmount);
    event Withdrawn(address indexed owner, uint256 usdtAmount);
    event KycVerifierUpdated(address newVerifier);

    constructor(
        address _usdtToken,
        address _voteToken,
        address _kycVerifier
    ) Ownable(msg.sender) EIP712("KycStaking", "1") {
        require(_usdtToken != address(0) && _voteToken != address(0), "Invalid token address");
        require(_kycVerifier != address(0), "Invalid kycVerifier address");
        usdtToken = IERC20(_usdtToken);
        voteToken = IERC20(_voteToken);
        kycVerifier = _kycVerifier;
    }

    function deposit(uint256 usdtAmount, uint256 deadline, bytes memory signature)
        external
        whenNotPaused
        nonReentrant
    {
        require(usdtAmount > 0, "Amount must be greater than 0");
        require(block.timestamp <= deadline, "Signature expired");

        if (!hasKycVerified[msg.sender]) {
            bytes32 structHash = keccak256(
                abi.encode(
                    KYC_VERIFICATION_TYPEHASH,
                    msg.sender,
                    deadline
                )
            );
            bytes32 hash = _hashTypedDataV4(structHash);
            address signer = hash.recover(signature);
            require(signer == kycVerifier, "Invalid KYC signature");
            hasKycVerified[msg.sender] = true;
        }

        uint256 voteAmount = (usdtAmount * VOTE_PER_USDT) / 10**18;
        require(voteAmount > 0, "Vote amount too small");

        require(
            usdtToken.allowance(msg.sender, address(this)) >= usdtAmount,
            "Insufficient USDT allowance"
        );
        require(
            usdtToken.balanceOf(msg.sender) >= usdtAmount,
            "Insufficient USDT balance"
        );

        require(usdtToken.transferFrom(msg.sender, address(this), usdtAmount), "USDT transfer failed");

        unchecked {
            userDeposits[msg.sender] += usdtAmount;
            pendingVotes[msg.sender] += voteAmount;
        }

        emit Deposited(msg.sender, usdtAmount, voteAmount);
    }

    function claimVotes()
        external
        whenNotPaused
        nonReentrant
    {
        uint256 voteAmount = pendingVotes[msg.sender];
        require(voteAmount > 0, "No votes to claim");

        pendingVotes[msg.sender] = 0;
        require(voteToken.transfer(msg.sender, voteAmount), "VOTE transfer failed");

        emit VotesClaimed(msg.sender, voteAmount);
    }

    function withdrawUSDT(uint256 amount)
        external
        onlyOwner
        nonReentrant
    {
        uint256 balance = usdtToken.balanceOf(address(this));
        require(amount <= balance, "Insufficient USDT balance");

        require(usdtToken.transfer(owner(), amount), "USDT withdrawal failed");

        emit Withdrawn(owner(), amount);
    }

    function setKycVerifier(address newVerifier) external onlyOwner {
        require(newVerifier != address(0), "Invalid address");
        kycVerifier = newVerifier;
        emit KycVerifierUpdated(newVerifier);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function getUserData(address user)
        external
        view
        returns (uint256 deposited, uint256 votesPending)
    {
        deposited = userDeposits[user];
        votesPending = pendingVotes[user];
    }

    function getContractBalance()
        external
        view
        onlyOwner
        returns (uint256 usdtBalance, uint256 voteBalance)
    {
        usdtBalance = usdtToken.balanceOf(address(this));
        voteBalance = voteToken.balanceOf(address(this));
    }

    function emergencyWithdraw(address token, uint256 amount)
        external
        onlyOwner
        nonReentrant
    {
        require(token != address(usdtToken), "Cannot withdraw USDT this way");
        require(IERC20(token).transfer(owner(), amount), "Emergency withdraw failed");
    }
}