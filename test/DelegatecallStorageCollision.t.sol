// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {StorageCollisionModule} from "../src/delegatecall/StorageCollisionModule.sol";
import {VulnerableDelegateCaller} from "../src/delegatecall/VulnerableDelegateCaller.sol";
import {FixedExternalCaller} from "../src/delegatecall/FixedExternalCaller.sol";

contract DelegatecallStorageCollisionTest is Test {
    address private constant COLLIDING_VALUE = address(0xBEEF);
    uint256 private constant MODULE_VALUE = 777;

    function testDelegatecallOverwritesOwnerAtMatchingSlotZero() public {
        StorageCollisionModule module = new StorageCollisionModule();
        VulnerableDelegateCaller caller = new VulnerableDelegateCaller();

        assertEq(caller.owner(), address(this), "initial owner should be deployer");

        // The module's slot-0 value is written into the caller's slot-0 owner.
        caller.delegateSetValue(address(module), uint256(uint160(COLLIDING_VALUE)));

        assertEq(caller.owner(), COLLIDING_VALUE, "delegatecall should corrupt owner slot");
    }

    function testNormalExternalCallKeepsCallerOwnerAndWritesModuleStorage() public {
        StorageCollisionModule module = new StorageCollisionModule();
        FixedExternalCaller caller = new FixedExternalCaller();

        caller.callModule(address(module), MODULE_VALUE);

        assertEq(caller.owner(), address(this), "caller owner must remain unchanged");
        assertEq(module.value(), MODULE_VALUE, "module should update its own storage");
    }

    function testNonOwnerCannotInvokeVulnerableDelegateFunction() public {
        StorageCollisionModule module = new StorageCollisionModule();
        VulnerableDelegateCaller caller = new VulnerableDelegateCaller();

        vm.expectRevert(VulnerableDelegateCaller.Unauthorized.selector);
        vm.prank(address(0xBEEF));
        caller.delegateSetValue(address(module), MODULE_VALUE);

        assertEq(caller.owner(), address(this));
    }

    function testNonOwnerCannotInvokeFixedExternalFunction() public {
        StorageCollisionModule module = new StorageCollisionModule();
        FixedExternalCaller caller = new FixedExternalCaller();

        vm.expectRevert(FixedExternalCaller.Unauthorized.selector);
        vm.prank(address(0xBEEF));
        caller.callModule(address(module), MODULE_VALUE);

        assertEq(caller.owner(), address(this));
        assertEq(module.value(), 0);
    }
}
