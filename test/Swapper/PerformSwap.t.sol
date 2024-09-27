// SPDX-License-Identifier: MIT
pragma solidity >=0.8.25;
import "../TestSetup.sol";

contract PerformSwapTests is TestSetup {

    bytes32[] public aliceProof;
    bytes32[] public invalidAliceProof;

    function setUp() public {
        setUpTests();
        setUpMerkle();
        //setUpAliceWithDai();

        aliceProof = merkle.getProof(whitelistedAddresses, 0);
    }

    function test_FailsIfNotOnWhitelist() public {
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(INVALID_PROOF.selector));
        swapper.performSwap{value: 2 ether}(
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
        vm.expectRevert(abi.encodeWithSelector(INCORRECT_VALUE.selector));
        swapper.performSwap{value: 1 ether}(
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
        assertEq(swapper.gasFeeReimbursements(address(alice)), 0);

        vm.startPrank(alice);
        uint256 amountReceived = swapper.performSwap{value: 2 ether}(
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
        assertEq(swapper.gasFeeReimbursements(address(alice)), 0.001 ether);
    }

    function test_PerformSwapFromERC20ToWETH() public {
        vm.startPrank(alice);
        setUpAliceWithDai();

        uint256 aliceDaiBalance = IERC20(daiAddress).balanceOf(address(alice));
        assertEq(swapper.gasFeeReimbursements(address(alice)), 0.001 ether);

        IERC20(daiAddress).approve(address(swapper), 2 ether);
        uint256 amountReceived = swapper.performSwap{value: 0}(
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
        assertEq(swapper.gasFeeReimbursements(address(alice)), 0.002 ether);
    }

    function test_PerformSwapFromERC20ToERC20() public {
        vm.startPrank(alice);
        setUpAliceWithDai();

        uint256 aliceDaiBalance = IERC20(daiAddress).balanceOf(address(alice));
        uint256 aliceUsdcBalance = IERC20(usdcAddress).balanceOf(address(alice));
        assertEq(swapper.gasFeeReimbursements(address(alice)), 0.001 ether);

        IERC20(daiAddress).approve(address(swapper), 2 ether);
        uint256 amountReceived = swapper.performSwap{value: 0}(
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
        assertEq(swapper.gasFeeReimbursements(address(alice)), 0.002 ether);
    }

    function setUpAliceWithDai() public {
        swapper.performSwap{value: 4 ether}(
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