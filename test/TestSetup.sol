// SPDX-License-Identifier: MIT
pragma solidity >=0.8.25;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v3-periphery/contracts/interfaces/IQuoter.sol";
import "../src/RewardToken.sol";
import "../src/Swapper.sol";

contract TestSetup is Test {

    RewardToken public rewardToken;
    Swapper public swapper;
    IERC20 public wEth;
    IQuoter public uniswapQuote;

    address owner = vm.addr(1);
    address alice = vm.addr(2);
    address bob = vm.addr(3);
    address robyn = vm.addr(4);

    address wEthAddress = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address uniswapRouterV3 = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
    address quoterAddress = 0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6;
    
    function setUpTests() public {    
        vm.selectFork(vm.createFork(vm.envString("MAINNET_RPC_URL")));

        vm.deal(alice, 100 ether);
        vm.deal(owner, 100 ether);
        vm.deal(bob, 100 ether);
        vm.deal(robyn, 100 ether);

        vm.startPrank(owner);

        rewardToken = new RewardToken("RewardToken", "RT");
        swapper = new Swapper(uniswapRouterV3, wEthAddress, address(rewardToken));

        wEth = IERC20(wEthAddress);
        uniswapQuote = IQuoter(quoterAddress);
        vm.stopPrank();
    }
}