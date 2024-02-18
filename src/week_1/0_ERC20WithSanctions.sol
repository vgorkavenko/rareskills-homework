// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @dev Extends the ERC20 standard to include the ability to sanction addresses by the owner.
contract ERC20WithSanctions is ERC20 {
    error OnlyOwner();
    error SanctionedAddress(address);

    address public owner;
    mapping(address => bool) public sanctioned;

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert OnlyOwner();
        _;
    }

    modifier notSanctioned(address _address) {
        if (sanctioned[_address]) revert SanctionedAddress(_address);
        _;
    }

    function mint(address account, uint256 amount) external onlyOwner {
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) external onlyOwner {
        _burn(account, amount);
    }

    function sanctionAddress(address _address) external onlyOwner {
        sanctioned[_address] = true;
    }

    function removeSanction(address _address) external onlyOwner {
        sanctioned[_address] = false;
    }

    /// @inheritdoc ERC20
    function transfer(address to, uint256 amount)
        public
        override
        notSanctioned(msg.sender)
        notSanctioned(to)
        returns (bool)
    {
        return super.transfer(to, amount);
    }

    /// @inheritdoc ERC20
    function transferFrom(address from, address to, uint256 amount)
        public
        override
        notSanctioned(from)
        notSanctioned(to)
        returns (bool)
    {
        return super.transferFrom(from, to, amount);
    }
}
