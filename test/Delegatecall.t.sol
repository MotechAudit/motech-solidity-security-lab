// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/delegatecall/VulnerableLibrary.sol";
import "../src/delegatecall/VulnerableDelegateCaller.sol";
import "../src/delegatecall/FixedLibrary.sol";
import "../src/delegatecall/FixedDelegateCaller.sol";

contract DelegatecallTest is Test {
    VulnerableLibrary internal vulnerableLibrary;
    VulnerableDelegateCaller internal vulnerableCaller;
    FixedLibrary internal fixedLibrary;
    FixedDelegateCaller internal fixedCaller;

    address internal constant ATTACKER = address(0xA77aCCE000000000000000000000000000000000);

    function setUp() public {
        vulnerableLibrary = new VulnerableLibrary();
        vulnerableCaller = new VulnerableDelegateCaller(address(vulnerableLibrary));
        fixedLibrary = new FixedLibrary();
        fixedCaller = new FixedDelegateCaller(address(fixedLibrary));
    }

    function testVulnerableDelegatecallOverwritesOwner() public {
        address ownerBefore = vulnerableCaller.owner();
        address implementationBefore = vulnerableCaller.implementation();

        assertEq(ownerBefore, address(this));
        assertEq(vulnerableCaller.value(), 0);

        // The attacker's address, passed as a plain number. The library
        // writes it to slot 0, which is `owner` in the caller.
        vulnerableCaller.setValue(uint256(uint160(ATTACKER)));

        // The owner is replaced by the attacker; the intended variable
        // (`value`, slot 1) is never updated.
        assertEq(vulnerableCaller.owner(), ATTACKER);
        assertEq(vulnerableCaller.value(), 0);
        // The implementation address itself (slot 2) is untouched.
        assertEq(vulnerableCaller.implementation(), implementationBefore);
    }

    function testVulnerableDelegatecallRunsInCallerStorageContext() public {
        vulnerableCaller.setValue(1234);

        // The library's own storage is never touched: the code ran in the
        // caller's storage context, not in the library's.
        assertEq(vulnerableLibrary.storedValue(), 0);
        // The write landed on the caller's slot 0 instead.
        assertEq(vulnerableCaller.owner(), address(uint160(1234)));
    }

    function testVulnerableDelegatecallWithMaxUintCorruptsOwner() public {
        vulnerableCaller.setValue(type(uint256).max);

        // Only the low 160 bits fit in an address slot.
        assertEq(vulnerableCaller.owner(), address(type(uint160).max));
        assertEq(vulnerableCaller.value(), 0);
    }

    function testFixedDelegatecallKeepsOwnerAndUpdatesValue() public {
        address ownerBefore = fixedCaller.owner();

        fixedCaller.setValue(42);

        // Aligned layouts: the write lands on `value` (slot 1), and the
        // owner (slot 0) is untouched.
        assertEq(fixedCaller.owner(), ownerBefore);
        assertEq(fixedCaller.owner(), address(this));
        assertEq(fixedCaller.value(), 42);
        // The library's own storage is still untouched; the code ran in
        // the caller's storage context, on the correct slot this time.
        assertEq(fixedLibrary.value(), 0);
    }

    function testFixedDelegatecallRepeatedCallsStayAligned() public {
        fixedCaller.setValue(7);
        fixedCaller.setValue(99);
        fixedCaller.setValue(1);

        assertEq(fixedCaller.owner(), address(this));
        assertEq(fixedCaller.value(), 1);
    }
}
