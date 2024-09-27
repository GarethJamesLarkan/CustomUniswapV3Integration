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
        swapper.updateMerkleRoot(0x0);
    }

    function test_UpdateMerkleRoot() public {
        //assertEq(swapper.merkleRoot(), swapper.merkleRoot());
        vm.startPrank(owner);
        vm.expectEmit(true, false, false, false);
        emit UpdatedMerkleRoot(0x0);
        swapper.updateMerkleRoot(0x0);
        assertEq(swapper.merkleRoot(), 0x0);
    }
}