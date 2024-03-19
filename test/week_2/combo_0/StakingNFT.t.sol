// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import { SimpleERC20 } from "../../../src/week_2/combo_0/SimpleERC20.sol";
import { NFTWithDiscount } from "../../../src/week_2/combo_0/NFTWithDiscount.sol";
import { StakingContract } from "../../../src/week_2/combo_0/StakingContract.sol";
import { Test } from "forge-std/Test.sol";

contract NFTWithDiscountTestable is NFTWithDiscount {
    constructor(address owner, bytes32 merkleRoot, uint256 discount) NFTWithDiscount(owner, merkleRoot, discount) { }

    function _proofIsValid(bytes32[] calldata proof, uint256 index) internal view override returns (bool) {
        return true;
    }
}

contract StakingNFTTest is Test {

    NFTWithDiscountTestable public nft;
    SimpleERC20 public rewardToken;
    StakingContract public stakingContract;

    function setUp() public {
        nft = new NFTWithDiscountTestable(address(this), bytes32(0), 5000); // 50%
        rewardToken = new SimpleERC20("RewardToken", "RT");
        stakingContract = new StakingContract(address(nft), address(rewardToken));
    }

    function test_mint() public {
        vm.deal(address(this), 1 ether);
        nft.mint{value: 1 ether}();
        assertEq(nft.totalSupply(), 1);
    }

    function test_mintWithDiscount() public {
        vm.deal(address(this), 0.5 ether);
        nft.mintWithDiscount{value: 0.5 ether}(new bytes32[](0), 0);
        assertEq(nft.totalSupply(), 1);
    }

    function test_stake_and_withdraw() public {
        vm.deal(address(this), 1 ether);
        nft.mint{value: 1 ether}();
        nft.approve(address(stakingContract), 0);
        nft.safeTransferFrom(address(this), address(stakingContract), 0);
        assertEq(stakingContract.tokensStakers(0), address(this));
        assertEq(nft.ownerOf(0), address(stakingContract));

        skip(5 days);

        assertEq(stakingContract.getRewardsAmount(), 50);
        stakingContract.claimRewards();
        assertEq(rewardToken.balanceOf(address(this)), 50);

        skip(1 days);

        stakingContract.withdraw(0);
        assertEq(rewardToken.balanceOf(address(this)), 60);
        assertEq(stakingContract.tokensStakers(0), address(0));
        assertEq(nft.ownerOf(0), address(this));
    }
}