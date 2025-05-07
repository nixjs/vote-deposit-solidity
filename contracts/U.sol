// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract U is ERC20 {
    constructor() ERC20("U", "U") {
        _mint(msg.sender, 100_000_000_000_000 * 10**18);
    }

    function decimals() public pure override returns (uint8) {
        return 18;
    }
}