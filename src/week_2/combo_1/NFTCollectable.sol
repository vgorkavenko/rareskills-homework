// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { ERC721Enumerable } from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract NFTCollectable is ERC721Enumerable {
    error CollectionSizeReached();
    error InvalidTokenId();

    uint256 constant public COLLECTION_SIZE = 20;
    uint256 constant public MAX_TOKEN_ID = 100;
    uint256 constant public MIN_TOKEN_ID = 1;


    constructor() ERC721("NFTCollectable", "NFTC") {
    }

    function mint(address to, uint256 tokenId) external {
        if (tokenId > MAX_TOKEN_ID) {
            revert InvalidTokenId();
        }
        if (tokenId < MIN_TOKEN_ID) {
            revert InvalidTokenId();
        }
        if (COLLECTION_SIZE < totalSupply()) {
            revert CollectionSizeReached();
        }
        _mint(to, tokenId);
    }
}