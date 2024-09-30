// SPDX-License-Identifier: MIT
pragma solidity >=0.8.25;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v3-periphery/contracts/interfaces/IQuoter.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "../lib/murky/src/Merkle.sol";
import "../src/Swapper.sol";
import "./TestERC20.sol";
import "./Swapper/ETHReverterContract.sol";

contract TestSetup is Test {

    Swapper public swapper;
    IERC20 public wEth;
    IQuoter public uniswapQuote;
    Merkle public merkle;

    bytes32 public merkleRoot;

    address owner = vm.addr(1);
    address alice = vm.addr(2);
    address bob = vm.addr(3);
    address robyn = vm.addr(4);

    address wEthAddress = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address usdcAddress = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address daiAddress = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address uniswapRouterV3 = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
    address uniswapFactoryV3 = 0x1F98431c8aD98523631AE4a59f267346ea31F984;
    address quoterAddress = 0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6;

    bytes32[] public whitelistedAddresses;

    error OwnableUnauthorizedAccount(address account);
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
    
    function setUpTests() public {    
        vm.selectFork(vm.createFork(vm.envString("MAINNET_RPC_URL")));

        vm.deal(alice, 100 ether);
        vm.deal(owner, 100 ether);
        vm.deal(bob, 100 ether);
        vm.deal(robyn, 100 ether);

        vm.startPrank(owner);
        swapper = new Swapper(uniswapRouterV3, uniswapFactoryV3, wEthAddress, quoterAddress);

        wEth = IERC20(wEthAddress);
        uniswapQuote = IQuoter(quoterAddress);
        vm.stopPrank();
    }

    function setUpMerkle() public {
        whitelistedAddresses.push(keccak256(abi.encodePacked(alice)));
        whitelistedAddresses.push(keccak256(abi.encodePacked(bob)));

        merkle = new Merkle();
        bytes32 merkleRootLocal = merkle.getRoot(whitelistedAddresses);
        merkleRoot = merkleRootLocal;

        vm.prank(owner);
        swapper.updateMerkleRoot(merkleRootLocal);
    }
}