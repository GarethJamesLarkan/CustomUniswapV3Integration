// SPDX-License-Identifier: MIT
pragma solidity >=0.8.25;
import "../TestSetup.sol";

contract PerformSwapTests is TestSetup {

    bytes32[] public aliceProof;
    bytes32[] public reverterContractProof;

    function setUp() public {
        setUpTests();
        setUpMerkle();

        aliceProof = merkle.getProof(whitelistedAddresses, 0);
    }

    function test_FailsIfETHTransferReverts() public {
        ETHReverterContract reverterContract = new ETHReverterContract();
        whitelistedAddresses.push(keccak256(abi.encodePacked(address(reverterContract))));

        vm.startPrank(owner);
        uniswapV3PrivateIntegrator.depositGasFeeReimbursement{value: 1 ether}();

        bytes32 newMerkleRootLocal = merkle.getRoot(whitelistedAddresses);
        merkleRoot = newMerkleRootLocal;
        uniswapV3PrivateIntegrator.updateMerkleRoot(newMerkleRootLocal);

        reverterContractProof = merkle.getProof(whitelistedAddresses, 2);
        vm.stopPrank();

        vm.deal(address(reverterContract), 10 ether);

        vm.startPrank(address(reverterContract));
        uniswapV3PrivateIntegrator.performSwap{value: 2 ether}(
            wEthAddress,
            usdcAddress,
            address(reverterContract),
            500,
            0.001 ether,
            30 minutes,
            2 ether,
            5,
            reverterContractProof
        );

        assertEq(uniswapV3PrivateIntegrator.gasFeeReimbursements(address(reverterContract)), 0.001 ether);

        vm.expectRevert(abi.encodeWithSelector(Eth_Transfer_Failed.selector));
        uniswapV3PrivateIntegrator.withdrawGasFeeReimbursement();
    }

    function test_FailsIfAmountOfGasFeesOwedIsMoreThanCurrentReimbursementBalance() public {
        vm.startPrank(alice);
        uniswapV3PrivateIntegrator.performSwap{value: 2 ether}(
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

        vm.expectRevert(abi.encodeWithSelector(Insufficient_Funds.selector));
        uniswapV3PrivateIntegrator.withdrawGasFeeReimbursement();
    }

    function test_WithdrawGasFeeReimbursement() public {
        vm.prank(owner);
        uniswapV3PrivateIntegrator.depositGasFeeReimbursement{value: 1 ether}();

        vm.startPrank(alice);
        uniswapV3PrivateIntegrator.performSwap{value: 2 ether}(
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
        uint256 aliceOwedGasFees = uniswapV3PrivateIntegrator.gasFeeReimbursements(address(alice));
        assertEq(address(uniswapV3PrivateIntegrator).balance, 1 ether);
        assertEq(aliceOwedGasFees, 0.001 ether);

        uniswapV3PrivateIntegrator.withdrawGasFeeReimbursement();
        assertEq(address(alice).balance, aliceEthBalanceBefore + aliceOwedGasFees);
        assertEq(address(uniswapV3PrivateIntegrator).balance, 0.999 ether);
        assertEq(uniswapV3PrivateIntegrator.gasFeeReimbursements(address(alice)), 0);
    }
}