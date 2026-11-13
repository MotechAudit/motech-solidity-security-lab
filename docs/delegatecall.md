# `delegatecall` storage collision

This educational example shows why `delegatecall` is dangerous when the
implementation contract's storage layout does not match the caller's.
`delegatecall` runs the implementation's code **in the caller's storage
context**: every storage write the implementation makes lands on the
caller's own storage slots, by slot number, not by variable name.

## Files

- `src/delegatecall/VulnerableLibrary.sol` — implementation whose slot 0 is a `uint256 storedValue`.
- `src/delegatecall/VulnerableDelegateCaller.sol` — caller whose slot 0 is `address owner` and slot 1 is `uint256 value`; it delegatecalls `setValue` on the library.
- `src/delegatecall/FixedLibrary.sol` — implementation whose slots 0–1 mirror the caller exactly (`owner`, then `value`).
- `src/delegatecall/FixedDelegateCaller.sol` — caller with the same aligned layout; it delegatecalls the fixed library.
- `test/Delegatecall.t.sol` — reproduces the overwrite in the vulnerable pair and verifies the correct behavior in the fixed pair.

## What happens

In the vulnerable pair, `setValue(attackerAddress)` delegatecalls
`VulnerableLibrary.setValue`, which writes to slot 0. In the caller,
slot 0 holds `owner`, so the owner is replaced by the supplied number
while `value` (slot 1) never changes. The library's own storage is
never touched — the test asserts `storedValue` stays `0`, proving the
code executed against the caller's storage.

In the fixed pair, both contracts declare slot 0 as `address owner`
and slot 1 as `uint256 value`, so the same `setValue` write lands on
`value` and the owner is untouched.

## Preconditions

- The caller uses `delegatecall` to an implementation it does not fully control or whose layout was not checked.
- The implementation writes to at least one storage slot whose position or type differs from the caller's layout at that slot.
- The caller holds a meaningful variable (here, `owner`) in one of the affected slots.

## Risk

Whoever can trigger the delegatecall can overwrite the caller's
variables: ownership, balances, pause flags, or implementation
addresses. In the test, a single call hands ownership to an arbitrary
address. In a real proxy, the same mismatch can hand over the whole
contract. The compiler gives no warning — the code compiles and the
call succeeds.

## Mitigation shown

Align the storage layouts explicitly: the implementation must declare
the caller's variables in the same order and with the same types, and
the alignment must be re-checked every time either contract changes.
This example shows the aligned pattern only. For real proxies, prefer
an established pattern such as EIP-1967 / UUPS, keep the implementation
upgradeable only by a trusted admin, and never delegatecall into
untrusted code.

## Run tests

Install [Foundry](https://getfoundry.sh/) and the test helper dependency, then run:

```bash
forge install foundry-rs/forge-std --no-git
forge test -vv
```

## Limitations

These contracts are intentionally simplified teaching examples, not
production proxies and not a complete audit. The fixed example is safe
only as long as the two layouts stay aligned; adding, removing, or
reordering a variable in one contract silently breaks the other.
Passing the tests does not prove a contract is secure. Do not deploy
the vulnerable example.
