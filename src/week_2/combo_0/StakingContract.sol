// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import { IERC721Receiver } from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import { SimpleERC20 } from "./SimpleERC20.sol";
import { NFTWithDiscount } from "./NFTWithDiscount.sol";

contract StakingContract is IERC721Receiver {
    error NothingToClaim();
    error WrongNFT();
    error NotStaker();

    event RewardsClaimed(address indexed to, uint256 amount);
    event TokenStaked(address indexed staker, uint256 tokenId);
    event TokenWithdrawn(address indexed staker, uint256 tokenId);

    uint256 constant public REWARDS_PERIOD = 1 days;
    uint256 constant public TOKENS_TO_REWARD = 10; // 10 tokens

    NFTWithDiscount private _stakedNFT;
    SimpleERC20 private _rewardToken;

    // address[1000] public tokensStakers; ???
    mapping(uint256 tokenId => address) public tokensStakers;
    mapping(address => uint256) public stakedTokensCount;
    mapping(address => uint256) public lastStakerClaimTimestamps;

    constructor(address nftAddress, address rewardTokenAddress) {
        _stakedNFT = NFTWithDiscount(nftAddress);
        _rewardToken = SimpleERC20(rewardTokenAddress);
    }

    function onERC721Received(address, address from, uint256 tokenId, bytes calldata) external override returns (bytes4) {
        if (msg.sender != address(_stakedNFT)) revert WrongNFT();

        tokensStakers[tokenId] = from;
        stakedTokensCount[from] += 1;
        emit TokenStaked(from, tokenId);
        return this.onERC721Received.selector;
    }

    function withdraw(uint256 tokenId) external {
        if (tokensStakers[tokenId] != msg.sender) revert NotStaker();
        
        uint256 rewards = getRewardsAmount();
        if (rewards != 0) _claimRewards(msg.sender, rewards);
        tokensStakers[tokenId] = address(0);
        stakedTokensCount[msg.sender] -= 1;

        _stakedNFT.transferFrom(address(this), msg.sender, tokenId);
        emit TokenWithdrawn(msg.sender, tokenId);
    }

    function claimRewards() external {
        if (stakedTokensCount[msg.sender] == 0) revert NotStaker();
        uint256 rewards = getRewardsAmount();
        if (rewards == 0) revert NothingToClaim();
        _claimRewards(msg.sender, rewards);
    }

    function _claimRewards(address staker, uint256 rewards) internal {
        lastStakerClaimTimestamps[staker] = block.timestamp;
        _rewardToken.mint(staker, rewards);
        emit RewardsClaimed(staker, rewards);
    }

    function getRewardsAmount() public view returns (uint256) {
        return calcRewardsAmount(stakedTokensCount[msg.sender], block.timestamp - lastStakerClaimTimestamps[msg.sender]);
    }

    function calcRewardsAmount(uint256 tokens, uint256 unclaimPeriod) public pure returns (uint256) {
        return tokens * TOKENS_TO_REWARD * unclaimPeriod / REWARDS_PERIOD;
    }
}