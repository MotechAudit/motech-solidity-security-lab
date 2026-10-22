# Authorization: `tx.origin` vs. `msg.sender`

This educational example demonstrates why `tx.origin` should not be used to authorize privileged wallet actions.

## Files

- `src/tx-origin/VulnerableTxOriginWallet.sol` — authorizes withdrawals when `tx.origin == owner`.
- `src/tx-origin/FixedOwnerWallet.sol` — authorizes withdrawals only when the immediate caller, `msg.sender`, is the owner.
- `test/TxOrigin.t.sol` — uses a forwarding contract to demonstrate the vulnerable behavior and test the safer pattern.

## Risk

`tx.origin` identifies the original transaction initiator. If an owner is tricked into interacting with a malicious intermediary, that intermediary can call a vulnerable wallet function while the original owner remains `tx.origin`. A check based only on `tx.origin` may therefore mistake the owner's transaction for direct authorization of the forwarded call.

## Mitigation shown

Use explicit access control based on the immediate caller, such as an `onlyOwner` modifier that checks `msg.sender`, or a properly designed role-based authorization mechanism. Review the complete call flow and all privileged functions rather than changing a single check in isolation.

## Run tests

Install [Foundry](https://getfoundry.sh/) and the test helper dependency, then run:

```bash
forge install foundry-rs/forge-std --no-git
forge test -vv
```

## Limitations

These contracts are intentionally simplified teaching examples, not production wallets and not a complete audit. Passing the tests does not prove a contract is secure. Do not deploy the vulnerable example.
