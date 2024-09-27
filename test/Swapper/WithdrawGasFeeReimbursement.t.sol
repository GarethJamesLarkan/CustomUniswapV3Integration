// SPDX-License-Identifier: MIT
pragma solidity >=0.8.25;
import "../TestSetup.sol";

contract PerformSwapTests is TestSetup {

    bytes32[] public aliceProof;

    function setUp() public {
        setUpTests();
        setUpMerkle();

        aliceProof = merkle.getProof(whitelistedAddresses, 0);
    }

    function test_FailsIfAmountOfGasFeesOwedIsMoreThanCurrentReimbursementBalance() public {
        vm.startPrank(alice);
        swapper.performSwap{value: 2 ether}(
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

        vm.expectRevert(abi.encodeWithSelector(INSUFFICIENT_FUNDS.selector));
        swapper.withdrawGasFeeReimbursement();
    }

    function test_WithdrawGasFeeReimbursement() public {
        vm.prank(owner);
        swapper.depositGasFeeReimbursement{value: 1 ether}();

        vm.startPrank(alice);
        swapper.performSwap{value: 2 ether}(
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

        uint256 aliceEthBalanceBefore = address(alice).balance;
        uint256 aliceOwedGasFees = swapper.gasFeeReimbursements(address(alice));
        assertEq(address(swapper).balance, 1 ether);
        assertEq(aliceOwedGasFees, 0.001 ether);

        swapper.withdrawGasFeeReimbursement();
        assertEq(address(alice).balance, aliceEthBalanceBefore + aliceOwedGasFees);
        assertEq(address(swapper).balance, 0.999 ether);
        assertEq(swapper.gasFeeReimbursements(address(alice)), 0);
    }
}