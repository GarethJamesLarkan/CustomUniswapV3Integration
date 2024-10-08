// SPDX-License-Identifier: MIT
pragma solidity >=0.8.25;
import "../TestSetup.sol";

contract UpdateMerkleRootTests is TestSetup {

    event UpdatedMerkleRoot(bytes32 merkleRoot);

    function setUp() public {
        setUpTests();
    }

    function test_OnlyOwnerCanCallUpdateMerkleRoot() public {
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(OwnableUnauthorizedAccount.selector, address(alice)));
        uniswapV3PrivateIntegrator.updateMerkleRoot(0x0);
    }

    function test_UpdateMerkleRoot() public {
        bytes32 newMerkleRoot = 0x626c756500000000000000000000000000000000000000000000000000000000;
        assertEq(uniswapV3PrivateIntegrator.merkleRoot(), 0x0);
        vm.startPrank(owner);
        vm.expectEmit(true, false, false, false);
        emit UpdatedMerkleRoot(newMerkleRoot);
        uniswapV3PrivateIntegrator.updateMerkleRoot(newMerkleRoot);
        assertEq(uniswapV3PrivateIntegrator.merkleRoot(), newMerkleRoot);
    }
}