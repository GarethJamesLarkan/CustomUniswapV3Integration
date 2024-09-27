// SPDX-License-Identifier: MIT
pragma solidity >=0.8.25;
import "../TestSetup.sol";

contract SwapperConstructorTests is TestSetup {

    function setUp() public {
        setUpTests();
    }

    function test_SwapperVariablesInitiatedCorrectly() public {
        assertEq(address(swapper.SWAP_ROUTER()), uniswapRouterV3);
        assertEq(address(swapper.WETH()), wEthAddress);
    }
}