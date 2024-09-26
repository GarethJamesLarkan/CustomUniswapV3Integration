// SPDX-License-Identifier: MIT
pragma solidity >=0.8.25;

import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./Interfaces/IWETH.sol";
import "./RewardToken.sol";

contract Swapper is Ownable2Step {
    using SafeERC20 for IERC20;

    bytes32 public merkleRoot;

    RewardToken public rewardToken;
    ISwapRouter public immutable SWAP_ROUTER;
    IWETH public immutable WETH;

    error Zero_Address();
    error Invalid_Proof();
    error Incorrect_Value();
    error Approval_Failed();

    event UpdatedMerkleRoot(bytes32 merkleRoot);

    constructor(
        address _uniswapV3SwapRouter,
        address _wethAddress,
        address _rewardToken
    ) Ownable(msg.sender) {
        isZeroAddress(_uniswapV3SwapRouter);
        isZeroAddress(_wethAddress);
        isZeroAddress(_rewardToken);
        rewardToken = RewardToken(_rewardToken);
        SWAP_ROUTER = ISwapRouter(_uniswapV3SwapRouter);
        WETH = IWETH(_wethAddress);
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
        if(!MerkleProof.verify(_merkleProof, merkleRoot, node)) revert Invalid_Proof();

        if (_tokenIn == address(WETH)) {
            if(msg.value != _amountIn) revert Incorrect_Value();
        } else {
            IERC20(_tokenIn).safeTransferFrom(msg.sender, address(this), _amountIn);
            if(!IERC20(_tokenIn).approve(address(SWAP_ROUTER), _amountIn)) revert Approval_Failed();
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

        amountReceived = SWAP_ROUTER.exactInputSingle{value: _tokenIn == address(WETH) ? _amountIn : 0}(params);
        rewardToken.mint(_recipient, amountReceived);
    }

    function updateMerkleRoot(bytes32 _newMerkleRoot) external onlyOwner {
        merkleRoot = _newMerkleRoot;
        emit UpdatedMerkleRoot(_newMerkleRoot);
    }

    function isZeroAddress(address _address) internal pure {
        if(_address == address(0)) {
            revert Zero_Address();
        }
    }
}
