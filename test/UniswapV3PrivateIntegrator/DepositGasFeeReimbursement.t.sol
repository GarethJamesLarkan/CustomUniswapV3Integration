// SPDX-License-Identifier: MIT
pragma solidity >=0.8.25;
import "../TestSetup.sol";

contract DepositGasFeeReimbursementTests is TestSetup {

    event GasFeeEthDeposited(uint256 amount);

    function setUp() public {
        setUpTests();
    }

    function test_OnlyOwnerCanCallDepositGasFeeReimbursement() public {
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(OwnableUnauthorizedAccount.selector, address(alice)));
        uniswapV3PrivateIntegrator.depositGasFeeReimbursement{value: 10 ether}();
    }

    function test_DepositGasFeeReimbursementEth() public {
        assertEq(uniswapV3PrivateIntegrator.amountOfEthForGasReimbursement(), 0);
        vm.startPrank(owner);
        vm.expectEmit(true, false, false, false);
        emit GasFeeEthDeposited(10 ether);
        uniswapV3PrivateIntegrator.depositGasFeeReimbursement{value: 10 ether}();
        assertEq(uniswapV3PrivateIntegrator.amountOfEthForGasReimbursement(), 10 ether);
    }
}