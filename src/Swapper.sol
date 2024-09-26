// SPDX-License-Identifier: MIT
pragma solidity >=0.8.25;

import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./Interfaces/IWETH.sol";

contract Swapper {
    using SafeERC20 for IERC20;

    ISwapRouter public immutable swapRouter;
    IWETH public immutable weth;

    error Zero_Address();

    constructor(
        address _uniswapV3SwapRouter,
        address _wethAddress
    ) {
        isZeroAddress(_uniswapV3SwapRouter);
        isZeroAddress(_wethAddress);
        swapRouter = ISwapRouter(_uniswapV3SwapRouter);
        weth = IWETH(_wethAddress);
    }

    function performSwap(
        address _tokenIn, 
        address _tokenOut
    ) external payable {
        if(msg.value > 0) {
            swapETHForERC20(_tokenOut, msg.value);
        } else if(_tokenOut == address(weth)) {
            swapERC20ForETH(_tokenIn);
        } else {
            swapERC20ForERC20(_tokenIn, _tokenOut);
        }
    }

    function swapETHForERC20(address _tokenOut, uint256 _amountIn) internal {

    }

    function swapERC20ForETH(address _tokenIn) internal {

    }

    function swapERC20ForERC20(address _tokenIn, address _tokenOut) internal {

    }

    function isZeroAddress(address _address) internal pure {
        if(_address == address(0)) {
            revert Zero_Address();
        }
    }
}
