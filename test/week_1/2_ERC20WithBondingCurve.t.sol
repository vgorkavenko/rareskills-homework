// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import { ERC20WithBondingCurve } from
    "../../src/week_1/2_ERC20WithBondingCurve.sol";

contract ERC20WithBondingCurveTest is Test {
    ERC20WithBondingCurve public erc20WithBondingCurve;
    address owner = address(0xf00d);
    address user = address(0xfeed);
    address stranger = address(0xdead);

    function setUp() public {
        vm.prank(owner);
        erc20WithBondingCurve =
            new ERC20WithBondingCurve("ERC20WithBondingCurve", "EBC", 1 ether);
    }

    function test_buy_and_sell() public {
        uint256 tokensToBuy = 1 ether;
        uint256 priceForUser =
            erc20WithBondingCurve.calcBuyPrice(tokensToBuy, erc20WithBondingCurve.totalSupply());

        // user buys
        vm.deal(user, priceForUser);
        vm.prank(user);
        erc20WithBondingCurve.buy{ value: priceForUser }(tokensToBuy);
        assertEq(erc20WithBondingCurve.balanceOf(user), tokensToBuy);
        assertEq(user.balance, 0 wei);

        uint256 priceForStranger =
            erc20WithBondingCurve.calcBuyPrice(tokensToBuy, erc20WithBondingCurve.totalSupply());

        // price for stranger should be higher because of the bonding curve
        assertGt(priceForStranger, priceForUser);

        // stranger buys
        vm.deal(stranger, priceForStranger);
        vm.prank(stranger);
        erc20WithBondingCurve.buy{ value: priceForStranger }(tokensToBuy);
        assertEq(erc20WithBondingCurve.balanceOf(stranger), tokensToBuy);
        assertEq(stranger.balance, 0 wei);

        // user sells back with profit
        vm.prank(user);
        erc20WithBondingCurve.sell(tokensToBuy);
        assertEq(erc20WithBondingCurve.balanceOf(user), 0 wei);
        assertEq(user.balance, priceForStranger);
    }

}
