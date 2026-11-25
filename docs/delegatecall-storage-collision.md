# Delegatecall storage collision

## The core rule

delegatecall runs another contract's code using the caller's storage context. The code comes from the target, but reads and writes to storage affect the calling contract.

Storage layout is therefore part of the compatibility boundary. If a module assumes that slot 0 is a uint256 value, while its caller uses slot 0 for an address owner, a write through delegatecall can overwrite the caller's owner variable.

## Reproduce the collision

- src/delegatecall/StorageCollisionModule.sol declares uint256 value as its first state variable (slot 0).
- src/delegatecall/VulnerableDelegateCaller.sol declares address owner as its first state variable (slot 0).
- The owner's delegateSetValue function delegates to the module. Setting the module's value to address(0xBEEF) writes that value into the caller's slot 0 and changes its owner.

The Foundry test asserts the owner before and after the delegated write.

## Safer comparison

src/delegatecall/FixedExternalCaller.sol uses a normal external call. The module then updates its own storage, leaving the caller's owner slot unchanged. This demonstrates storage isolation, not a drop-in replacement for an upgradeable proxy: ordinary calls do not share the caller's state.

For real proxy systems, use a well-reviewed architecture, maintain explicit and compatible storage layouts, validate implementation upgrades, lock initialization where appropriate, and test upgrade transitions. Namespaced storage patterns can reduce accidental collisions, but do not eliminate the need for careful review.

## Run

    forge install foundry-rs/forge-std --no-git
    forge test --match-path test/DelegatecallStorageCollision.t.sol -vv

## Limitations

These are minimal educational examples. The vulnerable call is owner-gated to isolate the storage-context issue: the example demonstrates that even an authorized delegatecall can corrupt state when the selected code has an incompatible layout. It does not model every proxy pattern, compiler layout detail, or upgrade threat. Do not deploy the vulnerable example. A passing test suite is not a security audit.
