// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import { ERC20, IERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import { SwapPair, IERC3156FlashBorrower } from "../../src/week_3-6/SwapPair.sol";
import { Test, console } from "forge-std/Test.sol";

contract MineERC20 is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) { }

    // Just to get rid of approval calls.
    function allowance(address, address) public pure override returns (uint256) {
        return type(uint256).max;
    }

    function mint(address to, uint256 value) external {
        _mint(to, value);
    }
}

contract Borrower is IERC3156FlashBorrower {


    function borrow(address pool, uint256 amount0, uint256 amount1, bytes calldata data) external {
        SwapPair(pool).flashLoan(amount0, amount1, data);
    }

        /**
     * @dev Receive a flash loan.
     * @param initiator The initiator of the loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param fee The additional amount of tokens to repay.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     * @return The keccak256 hash of "ERC3156FlashBorrower.onFlashLoan"
     */
    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32) {
        return keccak256("ERC3156FlashBorrower.onFlashLoan");
    }
}

contract UniswapTest is Test {
    MineERC20 token0;
    MineERC20 token1;

    SwapPair pool;
    Borrower borrower;

    address alice;
    address carol;

    function setUp() public {
        alice = address(0x123321);
        carol = address(0x123456);

        token0 = new MineERC20("X", "X");
        token1 = new MineERC20("Y", "Y");

        pool = new SwapPair(address(token0), address(token1));

        borrower = new Borrower();
    }

    function test_swap() public {
        token0.mint(address(this), 10_000);
        token1.mint(address(this), 40_000_000);

        pool.mint(token0.balanceOf(address(this)), token1.balanceOf(address(this)), 0);

        uint256 token1Amount = 2_111_598;
        token1.mint(address(this), token1Amount);

        pool.swap(0, token1Amount, 0, 0);
        assertApproxEqAbs(token0.balanceOf(address(this)), 500, 1);
    }

    function test_mint() public {
        token0.mint(address(this), 10_000);
        token1.mint(address(this), 40_000_000);

        pool.mint(token0.balanceOf(address(this)), token1.balanceOf(address(this)), 0);
        assertEq(pool.balanceOf(address(this)), 632_455);
    }

    function test_mint_firstFepositorAttack() public {
        token0.mint(address(this), 1);
        token1.mint(address(this), 1);

        pool.mint(1, 1, 0);

        token0.mint(alice, 100);
        token1.mint(alice, 100);

        vm.prank(alice);
        pool.mint(100, 100, 0);

        assertGt(pool.balanceOf(alice), 0, "attack succeeded");
    }

    function test_burn() public {
        {
            token0.mint(alice, 1e15);
            token1.mint(alice, 1e17);

            token0.mint(carol, 1e13);
            token1.mint(carol, 1e15);
        }

        vm.prank(alice);
        pool.mint(1e15, 1e17, 0);

        vm.prank(carol);
        pool.mint(1e13, 1e13, 0);

        uint256 liquidity = pool.balanceOf(carol);
        vm.prank(carol);
        pool.burn(liquidity, 0, 0);

        liquidity = pool.balanceOf(alice);
        vm.prank(alice);
        pool.burn(liquidity, 0, 0);

        assertApproxEqAbs(token0.balanceOf(alice), 1e15, 1, "err: token0(alice)");
        assertApproxEqAbs(token1.balanceOf(alice), 1e17, 1, "err: token1(alice)");

        assertApproxEqAbs(token0.balanceOf(carol), 1e13, 1, "err: token0(carol)");
        assertApproxEqAbs(token1.balanceOf(carol), 1e15, 1, "err: token1(carol)");
    }

    function test_flashLoan() public {
        {
            token0.mint(carol, 1000);
            token1.mint(carol, 1000);
            vm.prank(carol);
            pool.mint(1000, 1000, 0);
        }

        token0.mint(address(borrower), 3); // mint fee to repay loan

        {
            vm.expectEmit(true, true, true, true, address(token0));
            emit IERC20.Transfer(address(pool), address(borrower), 1000);

            vm.expectEmit(true, true, true, true, address(token1));
            emit IERC20.Transfer(address(pool), address(borrower), 100);

            borrower.borrow(address(pool), 1000, 100, "");
        }

        assertEq(pool.reserve0(), 1003, "loan wasn't repaid?");
        assertEq(pool.reserve1(), 1000, "loan wasn't repaid?");
    }

    function test_UniswapTWAP() public {
        uint256 delta = 108 seconds;

        {
            token0.mint(address(this), 1000);
            token1.mint(address(this), 2000);

            vm.warp(12 seconds);
            pool.mint(250, 500, 0);

            vm.warp(12 + delta);
            pool.mint(750, 1500, 0);
            // cumulativePrice0 = 500  / 250 * 108;
            // cumulativePrice1 = 250 / 500 * 108;
        }

        uint256 price;

        price = pool.cumulativePrice0() / delta;
        uint256 priceDecoded = price >> 112; 
        assertEq(priceDecoded, 2);
        assertEq(price, 2 << 112); // Q112.112(2.0)

        price = pool.cumulativePrice1() / delta;
        priceDecoded = price >> 112; 
        assertEq(priceDecoded, 0);
        assertEq(price, 1 << 111); // Q112.112(0.5)
    }
}
