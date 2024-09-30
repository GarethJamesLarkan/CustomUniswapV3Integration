// SPDX-License-Identifier: MIT
pragma solidity >=0.8.25;

import "../TestSetup.sol";

contract PerformSwapTests is TestSetup {
    
    event SwapExecuted(address tokenIn, address tokenOut, address recipient, uint256 amountOut);

    bytes32[] public aliceProof;
    bytes32[] public invalidAliceProof;

    function setUp() public {
        setUpTests();
        setUpMerkle();

        aliceProof = merkle.getProof(whitelistedAddresses, 0);
    }

    function test_FailsIfTokenInIsZeroAddress() public {
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(Zero_Address.selector));
        uniswapV3PrivateIntegrator.performSwap{value: 2 ether}(
            address(0),
            usdcAddress,
            address(alice),
            500,
            0.001 ether,
            30 minutes,
            2 ether,
            5,
            aliceProof
        );
    }

    function test_FailsIfTokenOutIsZeroAddress() public {
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(Zero_Address.selector));
        uniswapV3PrivateIntegrator.performSwap{value: 2 ether}(
            wEthAddress,
            address(0),
            address(alice),
            500,
            0.001 ether,
            30 minutes,
            2 ether,
            5,
            aliceProof
        );
    }

    function test_FailsIfRecipientIsZeroAddress() public {
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(Zero_Address.selector));
        uniswapV3PrivateIntegrator.performSwap{value: 2 ether}(
            wEthAddress,
            usdcAddress,
            address(0),
            500,
            0.001 ether,
            30 minutes,
            2 ether,
            5,
            aliceProof
        );
    }

    function test_FailsIfInvalidFeeTier() public {
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(Invalid_Fee_Tier.selector));
        uniswapV3PrivateIntegrator.performSwap{value: 2 ether}(
            wEthAddress,
            usdcAddress,
            address(alice),
            100,
            0.001 ether,
            30 minutes,
            2 ether,
            5,
            aliceProof
        );
    }

    function test_FailsIfInvalidSwapDeadline() public {
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(Invalid_Swap_Deadline.selector));
        uniswapV3PrivateIntegrator.performSwap{value: 2 ether}(
            wEthAddress,
            usdcAddress,
            address(alice),
            500,
            0.001 ether,
            31 minutes,
            2 ether,
            5,
            aliceProof
        );
    }

    function test_FailsIfInvalidAmountIn() public {
        vm.startPrank(alice);
        vm.expectRevert(abi.encodeWithSelector(Invalid_Amount_In.selector));
        uniswapV3PrivateIntegrator.performSwap{value: 0}(
            usdcAddress,
            daiAddress,
            address(alice),
            500,
            0.001 ether,
            30 minutes,
            0,
            5,
            aliceProof
        );
    }

    function test_FailsIfSlippageAmountGreaterThan100() public {
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(Invalid_Slippage_Amount.selector));
        uniswapV3PrivateIntegrator.performSwap{value: 2 ether}(
            wEthAddress,
            usdcAddress,
            address(alice),
            500,
            0.001 ether,
            30 minutes,
            2 ether,
            101,
            aliceProof
        );
    }

    function test_PerformSwapFailsIfNotOnWhitelist() public {
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(Invalid_Proof.selector));
        uniswapV3PrivateIntegrator.performSwap{value: 2 ether}(
            wEthAddress,
            usdcAddress,
            address(alice),
            500,
            0.001 ether,
            30 minutes,
            2 ether,
            5,
            invalidAliceProof
        );
    }

    function test_FailsIfSwappingFromEthWithIncorrectMsgValue() public {
        vm.startPrank(alice);
        vm.expectRevert(abi.encodeWithSelector(Incorrect_Value.selector));
        uniswapV3PrivateIntegrator.performSwap{value: 1 ether}(
            wEthAddress,
            usdcAddress,
            address(alice),
            500,
            0.001 ether,
            30 minutes,
            2 ether,
            5,
            aliceProof
        );
    }

    function test_PerformSwapFromEthToERC20() public {
        uint256 aliceEthBalance = address(alice).balance;
        uint256 aliceUsdcBalance = IERC20(usdcAddress).balanceOf(address(alice));
        assertEq(uniswapV3PrivateIntegrator.gasFeeReimbursements(address(alice)), 0);

        vm.startPrank(alice);
        uint256 amount = uniswapQuote.quoteExactInputSingle(wEthAddress, usdcAddress, 500, 2 ether, 0);
        vm.expectEmit();
        emit SwapExecuted(wEthAddress, usdcAddress, address(alice), amount);
        uint256 amountReceived = uniswapV3PrivateIntegrator.performSwap{value: 2 ether}(
            wEthAddress,
            usdcAddress,
            address(alice),
            500,
            0.001 ether,
            30 minutes,
            2 ether,
            5,
            aliceProof
        );

        assertEq(address(alice).balance, aliceEthBalance - 2 ether);
        assertEq(IERC20(usdcAddress).balanceOf(address(alice)), aliceUsdcBalance + amountReceived);
        assertEq(uniswapV3PrivateIntegrator.gasFeeReimbursements(address(alice)), 0.001 ether);
    }

    function test_PerformSwapFromERC20ToWETH() public {
        vm.startPrank(alice);
        setUpAliceWithDai();

        uint256 aliceDaiBalance = IERC20(daiAddress).balanceOf(address(alice));
        assertEq(uniswapV3PrivateIntegrator.gasFeeReimbursements(address(alice)), 0.001 ether);

        IERC20(daiAddress).approve(address(uniswapV3PrivateIntegrator), 2 ether);

        uint256 amount = uniswapQuote.quoteExactInputSingle(daiAddress, wEthAddress, 500, 2 ether, 0);
        vm.expectEmit();
        emit SwapExecuted(daiAddress, wEthAddress, address(alice), amount);

        uint256 amountReceived = uniswapV3PrivateIntegrator.performSwap{value: 0}(
            daiAddress,
            wEthAddress,
            address(alice),
            500,
            0.001 ether,
            30 minutes,
            2 ether,
            5,
            aliceProof
        );

        assertEq(IERC20(wEthAddress).balanceOf(address(alice)), amountReceived);
        assertEq(IERC20(daiAddress).balanceOf(address(alice)), aliceDaiBalance - 2 ether);
        assertEq(uniswapV3PrivateIntegrator.gasFeeReimbursements(address(alice)), 0.002 ether);
    }

    function test_PerformSwapFromERC20ToERC20() public {
        vm.startPrank(alice);
        setUpAliceWithDai();

        uint256 aliceDaiBalance = IERC20(daiAddress).balanceOf(address(alice));
        uint256 aliceUsdcBalance = IERC20(usdcAddress).balanceOf(address(alice));
        assertEq(uniswapV3PrivateIntegrator.gasFeeReimbursements(address(alice)), 0.001 ether);

        IERC20(daiAddress).approve(address(uniswapV3PrivateIntegrator), 2 ether);

        uint256 amount = uniswapQuote.quoteExactInputSingle(daiAddress, usdcAddress, 500, 2 ether, 0);
        vm.expectEmit();
        emit SwapExecuted(daiAddress, usdcAddress, address(alice), amount);

        uint256 amountReceived = uniswapV3PrivateIntegrator.performSwap{value: 0}(
            daiAddress,
            usdcAddress,
            address(alice),
            500,
            0.001 ether,
            30 minutes,
            2 ether,
            5,
            aliceProof
        );

        assertEq(IERC20(usdcAddress).balanceOf(address(alice)), aliceUsdcBalance + amountReceived);
        assertEq(IERC20(daiAddress).balanceOf(address(alice)), aliceDaiBalance - 2 ether);
        assertEq(uniswapV3PrivateIntegrator.gasFeeReimbursements(address(alice)), 0.002 ether);
    }

    function setUpAliceWithDai() public {
        uniswapV3PrivateIntegrator.performSwap{value: 4 ether}(
            wEthAddress,
            daiAddress,
            address(alice),
            500,
            0.001 ether,
            30 minutes,
            4 ether,
            5,
            aliceProof
        );
    }
}