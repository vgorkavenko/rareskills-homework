// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import "forge-std/Test.sol";

import { ERC20WithSanctions } from "../../src/week_1/0_ERC20WithSanctions.sol";

contract ERC20WithSanctionsTest is Test {
    ERC20WithSanctions public erc20WithSanctions;
    address owner = address(0xf00d);
    address user = address(0xfeed);
    address stranger = address(0xdead);

    function setUp() public {
        vm.prank(owner);
        erc20WithSanctions = new ERC20WithSanctions("ERC20WithSanctions", "EWS");
    }

    function test_mint() public {
        vm.prank(owner);
        erc20WithSanctions.mint(address(user), 100);
        assertEq(erc20WithSanctions.balanceOf(address(user)), 100);
    }

    function test_burn() public {
        vm.startPrank(owner);
        erc20WithSanctions.mint(address(user), 100);
        erc20WithSanctions.burn(address(user), 50);
        vm.stopPrank();
        assertEq(erc20WithSanctions.balanceOf(address(user)), 50);
    }

    function test_sanctionAddress() public {
        vm.prank(owner);
        erc20WithSanctions.sanctionAddress(address(user));
        assertTrue(erc20WithSanctions.sanctioned(address(user)));
    }

    function test_removeSanction() public {
        vm.startPrank(owner);
        erc20WithSanctions.sanctionAddress(address(user));
        erc20WithSanctions.removeSanction(address(user));
        vm.stopPrank();
        assertFalse(erc20WithSanctions.sanctioned(address(user)));
    }

    function test_transfer() public {
        vm.prank(owner);
        erc20WithSanctions.mint(address(user), 100);
        vm.prank(user);
        erc20WithSanctions.transfer(address(stranger), 50);
        assertEq(erc20WithSanctions.balanceOf(address(user)), 50);
        assertEq(erc20WithSanctions.balanceOf(address(stranger)), 50);
    }

    function test_transferFrom() public {
        vm.prank(owner);
        erc20WithSanctions.mint(address(user), 100);
        vm.startPrank(user);
        erc20WithSanctions.approve(address(user), 50);
        erc20WithSanctions.transferFrom(address(user), address(stranger), 50);
        vm.stopPrank();
        assertEq(erc20WithSanctions.balanceOf(address(user)), 50);
        assertEq(erc20WithSanctions.balanceOf(address(stranger)), 50);
    }

    function test_transfer_RevertWhen_SenderSanctioned() public {
        vm.prank(owner);
        erc20WithSanctions.sanctionAddress(address(user));
        vm.expectRevert(
            abi.encodeWithSelector(
                ERC20WithSanctions.SanctionedAddress.selector, address(user)
            )
        );
        vm.prank(user);
        erc20WithSanctions.transfer(address(stranger), 100);
    }

    function test_transfer_RevertWhen_RecipientSanctioned() public {
        vm.prank(owner);
        erc20WithSanctions.sanctionAddress(address(stranger));
        vm.expectRevert(
            abi.encodeWithSelector(
                ERC20WithSanctions.SanctionedAddress.selector, address(stranger)
            )
        );
        vm.prank(user);
        erc20WithSanctions.transfer(address(stranger), 100);
    }

    function test_transferFrom_RevertWhen_SenderSanctioned() public {
        vm.prank(owner);
        erc20WithSanctions.sanctionAddress(address(user));
        vm.expectRevert(
            abi.encodeWithSelector(
                ERC20WithSanctions.SanctionedAddress.selector, address(user)
            )
        );
        vm.prank(user);
        erc20WithSanctions.transferFrom(address(user), address(stranger), 100);
    }

    function test_transferFrom_RevertWhen_RecipientSanctioned() public {
        vm.prank(owner);
        erc20WithSanctions.sanctionAddress(address(stranger));
        vm.expectRevert(
            abi.encodeWithSelector(
                ERC20WithSanctions.SanctionedAddress.selector, address(stranger)
            )
        );
        vm.prank(user);
        erc20WithSanctions.transferFrom(address(user), address(stranger), 100);
    }

    function test_mint_RevertWhen_NotOwner() public {
        vm.prank(stranger);
        vm.expectRevert(ERC20WithSanctions.OnlyOwner.selector);
        erc20WithSanctions.mint(address(user), 100);
    }

    function test_burn_RevertWhen_NotOwner() public {
        vm.prank(stranger);
        vm.expectRevert(ERC20WithSanctions.OnlyOwner.selector);
        erc20WithSanctions.burn(address(user), 50);
    }

    function test_sanctionAddress_RevertWhen_NotOwner() public {
        vm.prank(stranger);
        vm.expectRevert(ERC20WithSanctions.OnlyOwner.selector);
        erc20WithSanctions.sanctionAddress(address(user));
    }

    function test_removeSanction_RevertWhen_NotOwner() public {
        vm.prank(stranger);
        vm.expectRevert(ERC20WithSanctions.OnlyOwner.selector);
        erc20WithSanctions.removeSanction(address(user));
    }
}
