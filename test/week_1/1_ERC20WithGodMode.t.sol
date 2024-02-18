// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import "forge-std/Test.sol";

import { ERC20WithGodMode } from "../../src/week_1/1_ERC20WithGodMode.sol";

contract ERC20WithGodModeTest is Test {
    ERC20WithGodMode public erc20WithGodMode;
    address owner = address(0xf00d);
    address user = address(0xfeed);
    address stranger = address(0xdead);

    function setUp() public {
        vm.prank(owner);
        erc20WithGodMode = new ERC20WithGodMode("ERC20WithGodMode", "EGM");
    }

    function test_mint() public {
        vm.prank(owner);
        erc20WithGodMode.mint(address(user), 100);
        assertEq(erc20WithGodMode.balanceOf(address(user)), 100);
    }

    function test_burn() public {
        vm.startPrank(owner);
        erc20WithGodMode.mint(address(user), 100);
        erc20WithGodMode.burn(address(user), 50);
        vm.stopPrank();
        assertEq(erc20WithGodMode.balanceOf(address(user)), 50);
    }

    function test_setSpecial() public {
        vm.prank(owner);
        erc20WithGodMode.setSpecial(address(user));
        assertEq(erc20WithGodMode.special(), address(user));
    }

    function test_transferWithNoAllowance() public {
        vm.prank(owner);
        erc20WithGodMode.mint(address(stranger), 100);
        vm.prank(owner);
        erc20WithGodMode.setSpecial(address(user));
        vm.prank(user);
        erc20WithGodMode.transferWithNoAllowance(
            address(stranger), address(user), 50
        );
        assertEq(erc20WithGodMode.balanceOf(address(user)), 50);
        assertEq(erc20WithGodMode.balanceOf(address(stranger)), 50);
    }

    function test_mint_RevertWhen_NotOwner() public {
        vm.prank(stranger);
        vm.expectRevert(ERC20WithGodMode.OnlyOwner.selector);
        erc20WithGodMode.mint(address(user), 100);
    }

    function test_burn_RevertWhen_NotOwner() public {
        vm.prank(stranger);
        vm.expectRevert(ERC20WithGodMode.OnlyOwner.selector);
        erc20WithGodMode.burn(address(user), 50);
    }

    function test_setSpecial_RevertWhen_NotOwner() public {
        vm.prank(stranger);
        vm.expectRevert(ERC20WithGodMode.OnlyOwner.selector);
        erc20WithGodMode.setSpecial(address(user));
    }
}
