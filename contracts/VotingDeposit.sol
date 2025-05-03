// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract VotingDeposit is Ownable, ReentrancyGuard, Pausable {
    IERC20 public immutable usdtToken;
    IERC20 public immutable voteToken;
    
    uint256 public constant VOTE_PER_USDT = 100;
    
    mapping(address => uint256) private userDeposits;
    mapping(address => uint256) private pendingVotes;
    
    event Deposited(address indexed user, uint256 usdtAmount, uint256 voteAmount);
    event VotesClaimed(address indexed user, uint256 voteAmount);
    event Withdrawn(address indexed owner, uint256 usdtAmount);
    event PendingVotesReset(address indexed user, uint256 oldAmount, uint256 newAmount);
    
    constructor(address _usdtToken, address _voteToken) Ownable(msg.sender) {
        require(_usdtToken != address(0) && _voteToken != address(0), "Invalid token address");
        usdtToken = IERC20(_usdtToken);
        voteToken = IERC20(_voteToken);
    }
    
    function deposit(uint256 usdtAmount) 
        external 
        whenNotPaused 
        nonReentrant 
    {
        require(usdtAmount > 0, "Amount must be greater than 0");
        
        uint256 voteAmount = usdtAmount * VOTE_PER_USDT;
        require(voteAmount > 0, "Vote amount too small");
        
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
        
        uint256 contractBalance = voteToken.balanceOf(address(this));
        require(contractBalance >= voteAmount, "Insufficient VOTE balance in contract");
        
        pendingVotes[msg.sender] = 0;
        require(voteToken.transfer(msg.sender, voteAmount), "VOTE transfer failed");
        
        emit VotesClaimed(msg.sender, voteAmount);
    }
    
    function resetPendingVotes(address user, uint256 newAmount) 
        external 
        onlyOwner 
    {
        uint256 oldAmount = pendingVotes[user];
        pendingVotes[user] = newAmount;
        emit PendingVotesReset(user, oldAmount, newAmount);
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