// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @dev Extends the ERC20 standard to include the ability to sanction addresses by the owner.
contract SimpleERC20 is ERC20 {

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
    }

    function mint(address account, uint256 amount) external {
        _mint(account, amount);
    }

}
