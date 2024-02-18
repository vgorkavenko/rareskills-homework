// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @dev Extends the ERC20 standard to include the ability where special address is able to transfer tokens between addresses at will.
contract ERC20WithGodMode is ERC20 {
    error OnlyOwner();
    error OnlySpecialSender();

    address public owner;
    address public special;

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert OnlyOwner();
        _;
    }

    modifier onlySpecialSender() {
        if (msg.sender != special) revert OnlySpecialSender();
        _;
    }

    function mint(address account, uint256 amount) external onlyOwner {
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) external onlyOwner {
        _burn(account, amount);
    }

    function setSpecial(address _special) external onlyOwner {
        special = _special;
    }

    /// @dev Allows the special address to transfer tokens between addresses without any restrictions.
    function transferWithNoAllowance(address from, address to, uint256 amount)
        external
        onlySpecialSender
        returns (bool)
    {
        _transfer(from, to, amount);
        return true;
    }
}
