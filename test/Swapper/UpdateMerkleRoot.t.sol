// SPDX-License-Identifier: MIT
pragma solidity >=0.8.25;
import "../TestSetup.sol";

contract UpdateMerkleRoot is TestSetup {

    function setUp() public {
        setUpTests();
    }

    function test_OnlyOwnerCanCallUpdateMerkleRoot() public view {
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(OwnableUnauthorizedAccount.selector, address(alice)));
        swapper.updateMerkleRoot(0x0);
    }

    function test_UpdateMerkleRoot() public {
        assertEq(swapper.merkleRoot(), 0x0);
        vm.prank(owner);
        swapper.updateMerkleRoot(0x1);
        assertEq(swapper.merkleRoot(), 0x1);
    }
}