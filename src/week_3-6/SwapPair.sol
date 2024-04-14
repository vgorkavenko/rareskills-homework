// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC3156FlashBorrower } from "@openzeppelin/contracts/interfaces/IERC3156FlashBorrower.sol";
import { ERC20 } from "solady/tokens/ERC20.sol";
import { FixedPointMathLib } from "solady/utils/FixedPointMathLib.sol";


// Uniswap-like pair contract
contract SwapPair is ERC20 {
    using FixedPointMathLib for uint256;

    event Swapped(address indexed from, uint256 amount0In, uint256 amount1In, uint256 amount0Out, uint256 amount1Out);
    event Updated(uint256 reserve0, uint256 reserve1);

    event Mint(address indexed to, uint256 amount0, uint256 amount1);
    event Burn(address indexed from, uint256 amount0, uint256 amount1);

    error InvalidK();
    error InvalidAmountToMintLP();
    error InvalidAmountToBorrow();
    error InvalidResponseFromBorrower();
    error InvalidReturnedAmount();
    error InsufficientLiquidity();
    error Slippage();

    string private constant lpName = "SwapPair";
    string private constant lpSymbol = "SWP";
    uint224 private constant CALC_PRECISION_ON_UPDATE = 2 ** 112;

    IERC20 public token0;
    IERC20 public token1;

    uint256 public reserve0;
    uint256 public reserve1;

    uint256 public cumulativePrice0;
    uint256 public cumulativePrice1;
    uint256 public lastUpdateTimestamp;

    constructor(address _token0, address _token1) {
        token0 = IERC20(_token0);
        token1 = IERC20(_token1);
    }

    function name() public pure override returns (string memory) {
        return lpName;
    }

    function symbol() public pure override returns (string memory) {
        return lpSymbol;
    }

    // @notice helper to calculate the min amount of token0 to receive
    // @dev also accounts for the 0.3% fee
    function getAmount0Out(uint256 amount1In) public view returns (uint256) {
        uint256 _amount1In = amount1In - (amount1In * 3 / 1000);
        return reserve0 * _amount1In / (reserve1 + _amount1In);
    }

    // @notice helper to calculate the min amount of token1 to receive
    // @dev also accounts for the 0.3% fee
    function getAmount1Out(uint256 amount0In) public view returns (uint256) {
        uint256 _amount0In = amount0In - (amount0In * 3 / 1000);
        return reserve1 * _amount0In / (reserve0 + _amount0In);
    }

    function mint(uint256 amount0In, uint256 amount1In) external returns (uint256 liquidity) {
        if (amount0In == 0 || amount1In == 0) revert InvalidAmountToMintLP();

        // read once to reduce gas
        uint256 _reserve0 = reserve0;
        uint256 _reserve1 = reserve1;
        uint256 _totalSupply = totalSupply();

        if (_totalSupply > 0) {
            liquidity = (amount0In * _totalSupply / _reserve0).min(amount1In * _totalSupply / _reserve1);
            // calculate optimal amounts to transfer
            amount0In = amount0In * liquidity / _totalSupply;
            amount1In = amount1In * liquidity / _totalSupply;
        } else {
            liquidity = (amount0In * amount1In).sqrt();
        }
        if (liquidity == 0) revert InsufficientLiquidity();

        token0.transferFrom(msg.sender, address(this), amount0In);
        token1.transferFrom(msg.sender, address(this), amount1In);

        _mint(msg.sender, liquidity);

        _update(_reserve0, _reserve1, _reserve0 + amount0In, _reserve1 + amount1In);
        emit Mint(msg.sender, amount0In, amount1In);
    }

    function burn() public {
        // read once to reduce gas
        uint256 _reserve0 = reserve0;
        uint256 _reserve1 = reserve1;
        uint256 _totalSupply = totalSupply();
        uint256 liquidity = balanceOf(msg.sender);

        uint256 amount0 = liquidity * _reserve0 / _totalSupply;
        uint256 amount1 = liquidity * _reserve1 / _totalSupply;

        if(amount0 == 0 || amount1 == 0) revert InsufficientLiquidity();

        _burn(address(this), liquidity);
        token0.transfer(msg.sender, amount0);
        token1.transfer(msg.sender, amount1);

        _update(_reserve0, _reserve1, _reserve0 - amount0, _reserve1 - amount1);
        emit Burn(msg.sender, amount0, amount1);
    }

    function swap(
        uint256 amount0In,
        uint256 amount1In,
        // slippage protection
        uint256 amount0OutMin,
        uint256 amount1OutMin
    ) public {

        uint256 amount0Out;
        uint256 amount1Out;

        // read once to reduce gas
        uint256 _reserve0 = reserve0;
        uint256 _reserve1 = reserve1;

        if (amount0In > 0) {
            token0.transferFrom(msg.sender, address(this), amount0In);
            // account 0.3% fee
            uint256 _amount0In = amount0In - (amount0In * 3 / 1000);
            amount1Out = _reserve1 * _amount0In / (_reserve0 + _amount0In);
            if (amount1Out > _reserve1) revert InsufficientLiquidity();
            if (amount1Out < amount1OutMin) revert Slippage();
            token1.transfer(msg.sender, amount1Out);
        }
        if (amount1In > 0) {
            token1.transferFrom(msg.sender, address(this), amount1In);
            // account 0.3% fee
            uint256 _amount1In = amount1In - (amount1In * 3 / 1000);
            amount0Out = _reserve0 * _amount1In / (_reserve1 + _amount1In);
            if (amount0Out > _reserve0) revert InsufficientLiquidity();
            if (amount0Out < amount0OutMin) revert Slippage();
            token0.transfer(msg.sender, amount0Out);
        }

        uint256 reserve0After = _reserve0 + amount0In - amount0Out;
        uint256 reserve1After = _reserve1 + amount1In - amount1Out;

        if (reserve0After * reserve1After < _reserve0 * _reserve1) {
            revert InvalidK();
        }
    
        _update(_reserve0, _reserve1, reserve0After, reserve1After);
        emit Swapped(msg.sender, amount0In, amount1In, amount0Out, amount1Out);
    }

    function flashLoan(uint256 token0ToBorrow, uint256 token1ToBorrow, bytes calldata data) external {
        // read once to reduce gas
        uint256 _reserve0 = reserve0;
        uint256 _reserve1 = reserve1;

        if (token0ToBorrow > _reserve0 || token1ToBorrow > _reserve1) {
            revert InvalidAmountToBorrow();
        }

        uint256 fee0;
        uint256 fee1;

        if (token0ToBorrow > 0) {
            token0.transfer(msg.sender, token0ToBorrow);
            fee0 = token0ToBorrow * 3 / 1000;
            bytes32 ret = IERC3156FlashBorrower(msg.sender).onFlashLoan(msg.sender, address(token0), token0ToBorrow, fee0, data);
            if (ret != keccak256("ERC3156FlashBorrower.onFlashLoan")) {
                revert InvalidResponseFromBorrower();
            }
            // force the borrower to return the tokens, but with the fee
            token0.transferFrom(msg.sender, address(this), token0ToBorrow + fee0);
        }
        if (token1ToBorrow > 0) {
            token1.transfer(msg.sender, token1ToBorrow);
            fee1 = token1ToBorrow * 3 / 1000;
            bytes32 ret = IERC3156FlashBorrower(msg.sender).onFlashLoan(msg.sender, address(token1), token1ToBorrow, fee1, data);
            if (ret != keccak256("ERC3156FlashBorrower.onFlashLoan")) {
                revert InvalidResponseFromBorrower();
            }
            // force the borrower to return the tokens, but with the fee
            token1.transferFrom(msg.sender, address(this), token1ToBorrow + fee0);
        }

        _update(_reserve0, _reserve1, _reserve0 + fee0, _reserve1 + fee1);
    }

    // @dev should be called after each swap, loan, mint or burn. updates reserves and cumulative price
    function _update(uint256 reserve0Before, uint256 reserve1Before, uint256 reserve0After, uint256 reserve1After) private {

        uint256 timeElapsed = block.timestamp - lastUpdateTimestamp;

        if (timeElapsed > 0 && reserve0Before > 0 && reserve1Before > 0) {
            // price based on the reserves after the last transaction from the previous block
            // it's needed to prevent price manipulation
            uint112 u112reserve0 = uint112(reserve0Before);
            uint112 u112reserve1 = uint112(reserve1Before);
            cumulativePrice0 += uint224(u112reserve1) * CALC_PRECISION_ON_UPDATE  / uint224(u112reserve0) * timeElapsed;
            cumulativePrice1 += uint224(u112reserve0) * CALC_PRECISION_ON_UPDATE / uint224(u112reserve1) * timeElapsed;
        }

        reserve0 = reserve0After;
        reserve1 = reserve1After;

        lastUpdateTimestamp = block.timestamp;

        emit Updated(reserve0After, reserve1After);
    }
    
}