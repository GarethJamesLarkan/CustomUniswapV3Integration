// SPDX-License-Identifier: MIT
pragma solidity >=0.8.25;
import "../TestSetup.sol";

contract SwapperConstructorTests is TestSetup {

    function setUp() public {
        setUpTests();
    }

    function test_FailsIfUniswapRouterV3IsZeroAddress() public {
        vm.expectRevert(abi.encodeWithSelector(ZERO_ADDRESS.selector));
        Swapper testSwapper = new Swapper(address(0), wEthAddress, quoterAddress);
    }

    function test_FailsIfWETHIsZeroAddress() public {
        vm.expectRevert(abi.encodeWithSelector(ZERO_ADDRESS.selector));
        Swapper testSwapper = new Swapper(uniswapRouterV3, address(0), quoterAddress);
    }

    function test_FailsIfUniswapQuoterIsZeroAddress() public {
        vm.expectRevert(abi.encodeWithSelector(ZERO_ADDRESS.selector));
        Swapper testSwapper = new Swapper(uniswapRouterV3, wEthAddress, address(0));
    }

    function test_SwapperVariablesInitiatedCorrectly() public {
        assertEq(address(swapper.SWAP_ROUTER()), uniswapRouterV3);
        assertEq(address(swapper.WETH()), wEthAddress);
        assertEq(address(swapper.quoter()), quoterAddress);
    }
}