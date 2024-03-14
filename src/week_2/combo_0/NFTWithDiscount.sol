// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { ERC721Royalty } from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import { Ownable2Step, Ownable } from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {BitMaps} from "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract NFTWithDiscount is Ownable2Step, ERC721Royalty {
    using BitMaps for BitMaps.BitMap;

    error InvalidDiscountMerkleRoot();
    error InvalidDiscountBasisPoints();
    error InvalidDiscountProof();
    error RoyaltiesTransferFailed();
    error SoldOut();
    error WrongPrice();

    event RoyaltiesClaimed(address indexed to, uint256 amount);
    event MintedWithDiscount(address indexed to, uint256 tokenId);

    uint256 public constant MAX_SUPPLY = 1000;
    uint256 public constant COMMON_PRICE = 1 ether;
    uint256 public constant BASIS_POINTS_DENOMINATOR = 10000; // = 100%
    
    bytes32 public immutable discountMerkleRoot;
    uint256 public immutable discountBasisPoints;
    uint256 public immutable priceWithDiscount;

    uint256 public totalSupply;

    BitMaps.BitMap private _discountedAddresses;

    constructor(
        address _owner,
        bytes32 _discountMerkleRoot,
        uint256 _discountBasisPoints
    ) Ownable(_owner) ERC721("NFTWithDiscount", "NFTWD") {
        // royalty for owner is 2.5%
        _setDefaultRoyalty(_owner, 250);
        if (_discountMerkleRoot == 0) revert InvalidDiscountMerkleRoot();
        discountMerkleRoot = _discountMerkleRoot;
        if (_discountBasisPoints > BASIS_POINTS_DENOMINATOR) revert InvalidDiscountBasisPoints();
        discountBasisPoints = _discountBasisPoints;
        priceWithDiscount = (COMMON_PRICE * discountBasisPoints) / BASIS_POINTS_DENOMINATOR;
    }

    function mint() external payable {
        if (msg.value < COMMON_PRICE) revert WrongPrice();
        _mint(msg.sender);
    }

    function mintWithDiscount(bytes32[] calldata proof, uint256 index) external payable {
        if (msg.value != priceWithDiscount) revert WrongPrice();
        // double hashing leaf to prevent second pre-image attack
        // the hashing algorithm follows "StandardMerkleTree" implementation from OpenZeppelin
        bytes32 proofLeaf = keccak256(bytes.concat(keccak256(abi.encodePacked(msg.sender, index))));
        if (!MerkleProof.verifyCalldata(proof, discountMerkleRoot, proofLeaf)) revert InvalidDiscountProof();
        _discountedAddresses.set(index);
        _mint(msg.sender);
        emit MintedWithDiscount(msg.sender, totalSupply);
    }

    function claimRoyalties(address to, uint256 amount) external onlyOwner {
        (bool sent,) = to.call{ value: amount }("");
        if (!sent) revert RoyaltiesTransferFailed();
        emit RoyaltiesClaimed(to, amount);
    }

    function _mint(address to) internal {
        unchecked {
            // totalSupply can't be more than MAX_SUPPLY, so it's safe to add 1
            totalSupply += 1;
        }
        if (MAX_SUPPLY < totalSupply) revert SoldOut();
        super._mint(to, totalSupply);
    }
}