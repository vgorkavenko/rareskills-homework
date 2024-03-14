// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import { IERC721Enumerable } from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract RewardChecker {

    IERC721Enumerable public nftCollectable;

    constructor(address _nftCollectable) {
        nftCollectable = IERC721Enumerable(_nftCollectable);
    }

    function getPrimeTokensCount(address owner) public view returns (uint256 primes) {
        uint256 ownersTokensCount = nftCollectable.balanceOf(owner);
        if (ownersTokensCount == 0) return 0;
        uint256 i;
        do {
            unchecked {
                uint256 tokenId = nftCollectable.tokenOfOwnerByIndex(owner, i);
                if (isPrimeId(tokenId) == 1) ++primes;
                ++i;
            }
        } while (i < ownersTokensCount);
    }

    function isPrimeId(uint256 id) public pure returns (uint256) {
        if (id == 1) {
            return 0;
        }
        if (id == 2) {
            return 1;
        }
        if (id % 2 == 0) {
            return 0;
        }
        if (id % 3 == 0) {
            return 0;
        }
        uint256 i = 5;
        while (id > i * i) {
            if (id % i == 0) {
                return 0;
            }
            if (id % (i + 2) == 0) {
                return 0;
            }
            i += 6;
        }
        return 1;
    }
}