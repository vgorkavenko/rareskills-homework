// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";

/// @notice One-time use escrow contract for ERC20 tokens
/// @dev This contract can be used to create simple escrow contracts through a factory if modified slightly
contract UntrustedEscrow {
    using Address for address;

    event Funded(address indexed buyer, address indexed seller, address indexed arbitrator, address token, uint256 amount);
    event Released();
    event Refunded();

    error WrongSender();
    error WrongArbitrator();
    error SellerAndArbitratorAreTheSame();
    error NotBuyer();
    error NotSeller();
    error NotArbitrator();
    error ZeroAddress();
    error ZeroAmount();
    error TransferFailed();

    error AlreadyPending();
    error AlreadyReleased();
    error AlreadyRefunded();
    error NotEligibleForRelease();
    error NotEligibleForRefund();


    uint256 public constant RETENTION_PERIOD = 3 days;

    IERC20 public token;
    address public buyer;
    address public seller;
    address public arbitrator;
    uint256 public amount;
    uint256 public releaseTime;
    bool public pending;
    bool public released;
    bool public refunded;

    constructor(address _seller, address _arbitrator) {
        if (_seller == address(0)) revert ZeroAddress();
        if (_arbitrator == address(0)) revert ZeroAddress();
        if (_seller == _arbitrator) revert SellerAndArbitratorAreTheSame();
        if (_seller == msg.sender) revert WrongSender();
        if (_arbitrator == msg.sender) revert WrongArbitrator();
        buyer = msg.sender;
        arbitrator = _arbitrator;
        seller = _seller;
    }

    /// @notice The buyer can fund the escrow with an ERC20 token
    function fund(address _token, uint256 _amount) external {
        if (msg.sender != buyer) revert NotBuyer();
        if (pending) revert AlreadyPending();
        if (released) revert AlreadyReleased();
        if (refunded) revert AlreadyRefunded();
        if (_token == address(0)) revert ZeroAddress();
        if (_amount == 0) revert ZeroAmount();

        token = IERC20(_token);

        uint256 balanceBefore = token.balanceOf(address(this));
        _callOptionalReturn(token, abi.encodeCall(token.transferFrom, (buyer, address(this), _amount)));
        uint256 balanceAfter = token.balanceOf(address(this));

        amount = balanceAfter - balanceBefore;
        
        pending = true;
        releaseTime = block.timestamp + RETENTION_PERIOD;

        emit Funded(buyer, seller, arbitrator, address(token), amount);
    }

    /// @notice The seller can release the funds after `RETENTION_PERIOD`
    function release() external {
        if (msg.sender != seller) revert NotSeller();
        if (released) revert AlreadyReleased();
        if (refunded) revert AlreadyRefunded();
        if (block.timestamp < releaseTime) revert NotEligibleForRelease();

        released = true;

        _callOptionalReturn(token, abi.encodeCall(token.transfer, (seller, amount)));

        emit Released();
    }

    /// @notice The arbitrator can refund the funds to the buyer before `RETENTION_PERIOD`
    function refund() external {
        if (msg.sender != arbitrator) revert NotArbitrator();
        if (released) revert AlreadyReleased();
        if (refunded) revert AlreadyRefunded();
        if (block.timestamp >= releaseTime) revert NotEligibleForRefund();

        refunded = true;

        _callOptionalReturn(token, abi.encodeCall(token.transfer, (buyer, amount)));

        emit Refunded();
    }

    // Copy from OpenZeppelin's SafeERC20 library
    function _callOptionalReturn(IERC20 _token, bytes memory data) private {
        bytes memory returndata = address(_token).functionCall(data);
        if (returndata.length != 0 && !abi.decode(returndata, (bool))) {
            revert TransferFailed();
        }
    }
}