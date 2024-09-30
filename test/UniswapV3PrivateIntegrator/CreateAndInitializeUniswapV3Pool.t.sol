// SPDX-License-Identifier: MIT
pragma solidity >=0.8.25;

import "../TestSetup.sol";

contract CreateAndInitializeUniswapV3PoolTests is TestSetup {

    bytes32[] public aliceProof;
    bytes32[] public invalidAliceProof;

    TestERC20 public testToken;

    event PoolCreated(address pool, address creator, address tokenA, address tokenB, uint160 priceRatio, uint24 fee);

    function setUp() public {
        setUpTests();
        setUpMerkle();

        aliceProof = merkle.getProof(whitelistedAddresses, 0);
        testToken = new TestERC20("Test Token", "TST");
    }

    function test_CreatePoolAndInitializeFailsIfNotOnWhitelist() public {
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(Invalid_Proof.selector));
        uniswapV3PrivateIntegrator.createAndInitializeUniswapV3Pool(
            wEthAddress, 
            usdcAddress, 
            0.1 ether,
            79228162514264337593543950336, 
            3000, 
            invalidAliceProof
        );
    }

    function test_FailsIfTokensAreIdentical() public {
        vm.startPrank(alice);
        vm.expectRevert(abi.encodeWithSelector(Tokens_Must_Be_Different.selector));
        uniswapV3PrivateIntegrator.createAndInitializeUniswapV3Pool(
            wEthAddress, 
            wEthAddress, 
            0.1 ether,
            79228162514264337593543950336, 
            3000, 
            aliceProof
        );
    }

    function test_FailsIfInvalidFeeTier() public {
        vm.startPrank(alice);
        vm.expectRevert(abi.encodeWithSelector(Invalid_Fee_Tier.selector));
        uniswapV3PrivateIntegrator.createAndInitializeUniswapV3Pool(
            wEthAddress, 
            usdcAddress, 
            0.1 ether,
            79228162514264337593543950336, 
            200, 
            aliceProof
        );
    }

    function test_FailsIfPoolAlreadyExists() public {
        vm.startPrank(alice);
        uniswapV3PrivateIntegrator.createAndInitializeUniswapV3Pool(
            address(testToken), 
            usdcAddress, 
            0.1 ether,
            79228162514264337593543950336, 
            3000, 
            aliceProof
        );

        vm.expectRevert(abi.encodeWithSelector(Pool_Already_Exists.selector));
        uniswapV3PrivateIntegrator.createAndInitializeUniswapV3Pool(
            address(testToken), 
            usdcAddress, 
            0.1 ether,
            79228162514264337593543950336, 
            3000, 
            aliceProof
        );
    }

    function test_UniswapV3PoolIsCreated() public {
        assertEq(uniswapV3PrivateIntegrator.gasFeeReimbursements(address(alice)), 0);
        vm.startPrank(alice);
        address poolAddress = uniswapV3PrivateIntegrator.createAndInitializeUniswapV3Pool(
            address(testToken), 
            usdcAddress, 
            0.1 ether,
            79228162514264337593543950336, 
            3000, 
            aliceProof
        );
        assertEq(uniswapV3PrivateIntegrator.gasFeeReimbursements(address(alice)), 0.1 ether);
    }
}