# Access Control: Vulnerable vs. Fixed

This educational example demonstrates how a missing authorization check on a privileged setter can let an arbitrary caller redirect accrued fees.

## Files

- `src/access-control/VulnerableFeeVault.sol` — `setFeeRecipient()` omits the `onlyOwner` check.
- `src/access-control/FixedFeeVault.sol` — requires the owner to update the fee recipient.
- `test/AccessControl.t.sol` — demonstrates the unauthorized redirection and tests the mitigation.

## Impact

In the vulnerable example, any address can replace `feeRecipient`. When the owner later performs a normal fee withdrawal, the funds are sent to the attacker-selected recipient. The attacker does not need to call the withdrawal function.

## Mitigation shown

Restrict privileged state changes with an explicit authorization check. This example uses an owner-only modifier and a custom `Unauthorized` error. Production projects may need role-based access control, multisig ownership, a timelock, safe ownership transfer, and tests for every privileged function.

## Run tests

Install [Foundry](https://getfoundry.sh/) and the test helper dependency, then run:

```bash
forge install foundry-rs/forge-std --no-git
forge test -vv
```

## Limitations

These are intentionally minimal teaching contracts, not production contracts or a complete audit. The example illustrates one access-control flaw only. Review authorization on all privileged operations, recipient validation, accounting, external calls, ownership recovery, and the full application's business logic before deployment. A passing test suite does not prove a contract is secure.

Do not deploy the vulnerable example.
