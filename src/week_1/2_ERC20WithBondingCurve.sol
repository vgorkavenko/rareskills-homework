// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @dev Extends the ERC20 standard to include the bonding curve functionality (simple linear curve)
contract ERC20WithBondingCurve is ERC20 {
    error InsufficientFunds();
    error TransferFailed();

    uint256 public constant CURVE_SLOPE_NUMERATOR = 1;
    uint256 public constant CURVE_SLOPE_DENOMINATOR = 2;

    constructor(string memory name, string memory symbol, uint256 initialSupply) ERC20(name, symbol) {
        _mint(msg.sender, initialSupply);
    }

    function buy(uint256 amount) external payable {
        uint256 price = calcBuyPrice(amount, totalSupply());
        if (msg.value != price) revert InsufficientFunds();
        _mint(msg.sender, amount);
    }

    function sell(uint256 amount) external {
        uint256 price = calcSellPrice(amount, totalSupply());
        _burn(msg.sender, amount);
        (bool success, ) = msg.sender.call{ value: price }("");
        if (!success) revert TransferFailed();
    }

    /// @dev Because it is a linear curve, the price for amount could be calculated as area of a trapezoid:
    /// S = 1/2 * (a + b) * h, where a and b are the parallel sides, and h is the height
    function calcBuyPrice(uint256 amount, uint256 supply)
        public
        pure
        returns (uint256)
    {
        return (amount / 2)
            * (tokenPrice(supply) + tokenPrice(supply + amount));
    }

    /// @dev Because it is a linear curve, the price for amount could be calculated as area of a trapezoid
    /// S = 1/2 * (a + b) * h, where a and b are the parallel sides, and h is the height
    function calcSellPrice(uint256 amount, uint256 supply)
        public
        pure
        returns (uint256)
    {
        return (amount / 2)
            * (tokenPrice(supply) + tokenPrice(supply - amount));
    }

    function tokenPrice(uint256 supply) public pure returns (uint256) {
        return CURVE_SLOPE_NUMERATOR * supply / CURVE_SLOPE_DENOMINATOR;
    }
}
