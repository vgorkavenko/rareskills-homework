// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import { UntrustedEscrow } from
    "../../src/week_1/3_UntrustedEscrow.sol";
import { ERC20WithGodMode } from "../../src/week_1/1_ERC20WithGodMode.sol";


contract UntrustedEscrowTest is Test {
    UntrustedEscrow public untrustedEscrow;
    ERC20WithGodMode public erc20WithGodMode;
    address owner = address(0xf00d);
    address user = address(0xfeed);
    address stranger = address(0xdead);

    function setUp() public {
        vm.startPrank(owner);
        untrustedEscrow = new UntrustedEscrow(address(user), address(stranger));
        erc20WithGodMode = new ERC20WithGodMode("ERC20WithGodMode", "EGM");
        erc20WithGodMode.mint(address(owner), 100 ether);
        vm.stopPrank();
    }

    function test_deal() public {
        // fund by owner
        vm.startPrank(owner);
        erc20WithGodMode.approve(address(untrustedEscrow), 100 ether);
        untrustedEscrow.fund(address(erc20WithGodMode), 100 ether);
        vm.stopPrank();
        assertEq(untrustedEscrow.amount(), 100 ether);

        // wait for release for user
        vm.warp(untrustedEscrow.RETENTION_PERIOD() + 1 seconds);
        vm.prank(user);
        untrustedEscrow.release();
        assertEq(erc20WithGodMode.balanceOf(address(user)), 100 ether);
    }
    
}
