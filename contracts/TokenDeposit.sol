// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TokenDeposit is Ownable, ReentrancyGuard, Pausable {
    IERC20 public immutable token;

    event Deposited(address indexed user, uint256 amount, string uuid);
    event Withdrawn(address indexed owner, uint256 amount);

    constructor(address _token) Ownable(msg.sender) {
        token = IERC20(_token);
    }

    function deposit(
        uint256 amount,
        string calldata uuid
    ) external whenNotPaused nonReentrant {
        require(amount > 0, "Invalid amount");
        require(bytes(uuid).length > 0, "Empty UUID");

        require(
            token.transferFrom(msg.sender, address(this), amount),
            "Transfer failed"
        );
        emit Deposited(msg.sender, amount, uuid);
    }

    function withdraw(uint256 amount) external onlyOwner nonReentrant {
        require(amount > 0, "Invalid amount");
        require(token.balanceOf(address(this)) >= amount, "Low balance");

        require(token.transfer(msg.sender, amount), "Transfer failed");
        emit Withdrawn(msg.sender, amount);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function getContractBalance() external view returns (uint256) {
        return token.balanceOf(address(this));
    }
}
