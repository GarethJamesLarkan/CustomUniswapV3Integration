// SPDX-License-Identifier: MIT
pragma solidity >=0.8.25;

import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./Interfaces/IWETH.sol";

contract Swapper {
    using SafeERC20 for IERC20;

    bytes32 public merkleRoot;

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
        address _tokenOut,
        address _recipient,
        uint24 _poolFee,
        uint256 _swapDeadline,
        uint256 _amountIn,
        uint256 _amountOutMin,
        bytes32[] memory _merkleProof
    ) external payable returns (uint256 amountReceived) {
        bytes32 node = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, merkleRoot, node), "Swapper: Invalid Proof");

        if (_tokenIn == address(weth)) {
            require(msg.value == _amountIn, "Swapper: Incorrect ETH Amount");
        } else {
            IERC20(_tokenIn).safeTransferFrom(msg.sender, address(this), _amountIn);
            IERC20(_tokenIn).approve(address(swapRouter), _amountIn);
        }

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            tokenIn: _tokenIn,
            tokenOut: _tokenOut,
            fee: _poolFee,
            recipient: _recipient,
            deadline: block.timestamp + _swapDeadline, 
            amountIn: _amountIn,
            amountOutMinimum: _amountOutMin,
            sqrtPriceLimitX96: 0 
        });

        amountReceived = swapRouter.exactInputSingle{value: _tokenIn == address(weth) ? _amountIn : 0}(params);
    }

    function isZeroAddress(address _address) internal pure {
        if(_address == address(0)) {
            revert Zero_Address();
        }
    }
}
