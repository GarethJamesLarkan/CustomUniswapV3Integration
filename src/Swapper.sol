// SPDX-License-Identifier: MIT
pragma solidity >=0.8.25;

import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/interfaces/IQuoter.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./Interfaces/IWETH.sol";

contract Swapper is Ownable2Step, ReentrancyGuard {
    using SafeERC20 for IERC20;

    uint256 public amountOfEthForGasReimbursement;
    bytes32 public merkleRoot;

    mapping(address account => uint256 amount) public gasFeeReimbursements;

    ISwapRouter public immutable SWAP_ROUTER;
    IUniswapV3Factory public immutable UNISWAP_V3_FACTORY;
    IQuoter public immutable QUOTER;
    IWETH public immutable WETH;

    error Zero_Address();
    error Invalid_Proof();
    error Incorrect_Value();
    error Eth_Transfer_Failed();
    error Insufficient_Funds();
    error Tokens_Must_Be_Different();
    error Invalid_Fee_Tier();
    error Pool_Already_Exists();
    error Invalid_Swap_Deadline();
    error Invalid_Amount_In();
    error Invalid_Slippage_Amount();

    event UpdatedMerkleRoot(bytes32 merkleRoot);
    event GasFeeReimbursement(address account, uint256 amount);
    event GasFeeEthDeposited(uint256 amount);
    event PoolCreated(address pool, address creator, address tokenA, address tokenB, uint160 priceRatio, uint24 fee);
    event SwapExecuted(address tokenIn, address tokenOut, address recipient, uint256 amountOut);

    constructor(address _uniswapV3SwapRouter, address _uniswapV3Factory, address _wethAddress, address _quoterAddress)
        Ownable(msg.sender)
    {
        isZeroAddress(_uniswapV3SwapRouter);
        isZeroAddress(_uniswapV3Factory);
        isZeroAddress(_wethAddress);
        isZeroAddress(_quoterAddress);
        SWAP_ROUTER = ISwapRouter(_uniswapV3SwapRouter);
        UNISWAP_V3_FACTORY = IUniswapV3Factory(_uniswapV3Factory);
        WETH = IWETH(_wethAddress);
        QUOTER = IQuoter(_quoterAddress);
    }

    //-------------------------------------------------------------------------
    //-------------------------- UNISWAP FUNCTIONS ----------------------------
    //-------------------------------------------------------------------------

    function createAndInitializeUniswapV3Pool(
        address _tokenA,
        address _tokenB,
        uint256 _estimatedGas,
        uint160 _sqrtPriceX96,
        uint24 _fee,
        bytes32[] memory _merkleProof
    ) external returns (address createdPool) {
        if (!MerkleProof.verify(_merkleProof, merkleRoot, keccak256(abi.encodePacked(msg.sender)))) {
            revert Invalid_Proof();
        }
        if (_tokenA == _tokenB) {
            revert Tokens_Must_Be_Different();
        }
        isValidFeeTier(_fee);

        createdPool = UNISWAP_V3_FACTORY.getPool(_tokenA, _tokenB, _fee);
        if (createdPool != address(0)) {
            revert Pool_Already_Exists();
        }

        gasFeeReimbursements[msg.sender] += _estimatedGas;

        createdPool = UNISWAP_V3_FACTORY.createPool(_tokenA, _tokenB, _fee);
        IUniswapV3Pool(createdPool).initialize(_sqrtPriceX96);

        emit PoolCreated(createdPool, msg.sender, _tokenA, _tokenB, _sqrtPriceX96, _fee);
    }

    function performSwap(
        address _tokenIn,
        address _tokenOut,
        address _recipient,
        uint24 _poolFee,
        uint256 _estimatedGas,
        uint256 _swapDeadline,
        uint256 _amountIn,
        uint256 _slippageAmount,
        bytes32[] memory _merkleProof
    ) external payable returns (uint256 amountOut) {
        validateSwap(
            _tokenIn,
            _tokenOut,
            _recipient,
            _poolFee,
            _swapDeadline,
            _amountIn,
            _slippageAmount
        );

        if (!MerkleProof.verify(_merkleProof, merkleRoot, keccak256(abi.encodePacked(msg.sender)))) {
            revert Invalid_Proof();
        }

        if (_tokenIn == address(WETH)) {
            if (msg.value != _amountIn) revert Incorrect_Value();
        } else {
            IERC20(_tokenIn).safeTransferFrom(msg.sender, address(this), _amountIn);
            uint256 allowance = IERC20(_tokenIn).allowance(address(this), address(SWAP_ROUTER));
            if (allowance < _amountIn) {
                IERC20(_tokenIn).safeIncreaseAllowance(address(SWAP_ROUTER), _amountIn - allowance);
            }
        }

        uint256 expectedAmount = QUOTER.quoteExactInputSingle(_tokenIn, _tokenOut, _poolFee, _amountIn, 0);
        uint256 slippageAmount = (expectedAmount * _slippageAmount) / 100;

        gasFeeReimbursements[msg.sender] += _estimatedGas;

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            tokenIn: _tokenIn,
            tokenOut: _tokenOut,
            fee: _poolFee,
            recipient: _recipient,
            deadline: block.timestamp + _swapDeadline,
            amountIn: _amountIn,
            amountOutMinimum: expectedAmount - slippageAmount,
            sqrtPriceLimitX96: 0
        });

        amountOut = SWAP_ROUTER.exactInputSingle{value: _tokenIn == address(WETH) ? _amountIn : 0}(params);

        emit SwapExecuted(_tokenIn, _tokenOut, _recipient, amountOut);
    }

    //-------------------------------------------------------------------------
    //------------------------ GENERAL PUBLIC FUNCTIONS -----------------------
    //-------------------------------------------------------------------------

    function withdrawGasFeeReimbursement() external nonReentrant {
        uint256 amount = gasFeeReimbursements[msg.sender];
        if (amount > amountOfEthForGasReimbursement) {
            revert Insufficient_Funds();
        }

        gasFeeReimbursements[msg.sender] = 0;

        (bool sent,) = msg.sender.call{value: amount}("");
        if (!sent) {
            revert Eth_Transfer_Failed();
        }
    }

    //-------------------------------------------------------------------------
    //-------------------------- ONLY OWNER FUNCTIONS -------------------------
    //-------------------------------------------------------------------------

    function updateMerkleRoot(bytes32 _newMerkleRoot) external onlyOwner {
        merkleRoot = _newMerkleRoot;
        emit UpdatedMerkleRoot(_newMerkleRoot);
    }

    function depositGasFeeReimbursement() external payable onlyOwner {
        amountOfEthForGasReimbursement += msg.value;
        emit GasFeeEthDeposited(msg.value);
    }

    //-------------------------------------------------------------------------
    //-------------------------- INTERNAL FUNCTIONS ---------------------------
    //-------------------------------------------------------------------------

    function validateSwap(
        address _tokenIn,
        address _tokenOut,
        address _recipient,
        uint24 _poolFee,
        uint256 _swapDeadline,
        uint256 _amountIn,
        uint256 _slippageAmount
    ) internal pure {
        isZeroAddress(_tokenIn);
        isZeroAddress(_tokenOut);
        isZeroAddress(_recipient);
        isValidFeeTier(_poolFee);
        if (_swapDeadline > 30 minutes) {
            revert Invalid_Swap_Deadline();
        }
        if (_amountIn == 0) {
            revert Invalid_Amount_In();
        }
        if (_slippageAmount > 100) {
            revert Invalid_Slippage_Amount();
        }
    }

    function isValidFeeTier(uint24 _fee) internal pure {
        if (_fee != 500 && _fee != 3000 && _fee != 10000) {
            revert Invalid_Fee_Tier();
        }
    }

    function isZeroAddress(address _address) internal pure {
        if (_address == address(0)) {
            revert Zero_Address();
        }
    }
}
