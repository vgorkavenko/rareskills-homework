// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { ERC721Enumerable } from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract NFTCollectable is ERC721Enumerable {
    error CollectionSizeReached();
    error InvalidTokenId();

    uint256 public constant MAX_SUPPLY = 20;


    constructor() ERC721("NFTCollectable", "NFTC") {
    }

    function mint(address to) external {
        uint256 _totalSupply = totalSupply();
        if (MAX_SUPPLY == _totalSupply) revert CollectionSizeReached();
        // start from 1
        super._mint(to, ++_totalSupply);
    }
}