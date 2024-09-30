// SPDX-License-Identifier: MIT
pragma solidity >=0.8.25;
import "../TestSetup.sol";

contract SwapperConstructorTests is TestSetup {

    function setUp() public {
        setUpTests();
    }

    function test_FailsIfUniswapRouterV3IsZeroAddress() public {
        vm.expectRevert(abi.encodeWithSelector(Zero_Address.selector));
        UniswapV3PrivateIntegrator uniswapV3Integrator = new UniswapV3PrivateIntegrator(address(0), uniswapFactoryV3, wEthAddress, quoterAddress);
    }

    function test_FailsIfUniswapFactory3IsZeroAddress() public {
        vm.expectRevert(abi.encodeWithSelector(Zero_Address.selector));
        UniswapV3PrivateIntegrator uniswapV3Integrator = new UniswapV3PrivateIntegrator(uniswapRouterV3, address(0), wEthAddress, quoterAddress);
    }

    function test_FailsIfWETHIsZeroAddress() public {
        vm.expectRevert(abi.encodeWithSelector(Zero_Address.selector));
        UniswapV3PrivateIntegrator uniswapV3Integrator = new UniswapV3PrivateIntegrator(uniswapRouterV3, uniswapFactoryV3, address(0), quoterAddress);
    }

    function test_FailsIfUniswapQuoterIsZeroAddress() public {
        vm.expectRevert(abi.encodeWithSelector(Zero_Address.selector));
        UniswapV3PrivateIntegrator uniswapV3Integrator = new UniswapV3PrivateIntegrator(uniswapRouterV3, uniswapFactoryV3, wEthAddress, address(0));
    }

    function test_SwapperVariablesInitiatedCorrectly() public {
        assertEq(address(uniswapV3PrivateIntegrator.SWAP_ROUTER()), uniswapRouterV3);
        assertEq(address(uniswapV3PrivateIntegrator.UNISWAP_V3_FACTORY()), uniswapFactoryV3);
        assertEq(address(uniswapV3PrivateIntegrator.WETH()), wEthAddress);
        assertEq(address(uniswapV3PrivateIntegrator.QUOTER()), quoterAddress);
    }
}