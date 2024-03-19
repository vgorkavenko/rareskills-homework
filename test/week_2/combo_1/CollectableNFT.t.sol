// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import { NFTCollectable } from "../../../src/week_2/combo_1/NFTCollectable.sol";
import { RewardChecker } from "../../../src/week_2/combo_1/RewardChecker.sol";
import { Test } from "forge-std/Test.sol";
import "forge-std/console.sol";

contract CollectableNFT is Test {

    NFTCollectable public nft;
    RewardChecker public rewardChecker;

    function setUp() public {
        nft = new NFTCollectable();
        rewardChecker = new RewardChecker(address(nft));
    }

    function test_getCountOfPrimeTokens() public {
        for (uint256 i = 0; i < 20; i++) {
            nft.mint(address(this));
        }

        uint256 count = rewardChecker.getPrimeTokensCount(address(this));
        // from 1 to 20, there are 8 prime numbers
        assertEq(count, 8);
    }

    /// forge-config: default.fuzz.runs = 101
    function testFuzz_isPrime(uint256 n) public {
        vm.assume(n > 1);
        vm.assume(n < 100);
        uint256 isPrime = rewardChecker.isPrimeId(n);
        console.logUint(isPrime);
        assertEq(isPrime, _isPrime(n));
    }

    function testGas_isPrime() public view {
        for (uint256 i = 1; i < 101; ++i) {
            rewardChecker.isPrimeId(i);
        }
    }


    function _isPrime(uint256 n) internal pure returns (uint256) {
        for (uint256 k = 2; k < n; k++) {
            if (n % k == 0) {
                return 0;
            }
        }
        return 1;
    }

}