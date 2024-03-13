// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @dev Extends the ERC20 standard to include the ability to sanction addresses by the owner.
contract SimpleERC20 is ERC20 {

    error NotStakingContract();

    address public stakingContract;

    constructor(string memory name, string memory symbol, address _stakingContract) ERC20(name, symbol) {
        stakingContract = _stakingContract;
    }

    modifier onlyStakingContract() {
        if (msg.sender != stakingContract) revert NotStakingContract();
        _;
    }

    function mint(address account, uint256 amount) external onlyStakingContract {
        _mint(account, amount);
    }

}
