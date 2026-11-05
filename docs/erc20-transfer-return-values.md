# ERC-20 transfer return values

## The integration mistake

The ERC-20 interface defines `transfer` as returning a boolean. Integrators must not assume every token signals failure by reverting. A token can return `false` and leave balances unchanged.

The example in [VulnerableTokenPayout.sol](../src/erc20/VulnerableTokenPayout.sol) ignores that return value and increments its internal `paidOut` accounting anyway. The matching test uses a mock token that returns `false` without moving tokens, proving that the contract's records can diverge from token balances.

## The mitigation

[FixedTokenPayout.sol](../src/erc20/FixedTokenPayout.sol) uses OpenZeppelin Contracts `SafeERC20.safeTransfer`. The lab pins OpenZeppelin Contracts to **v5.2.0** in its GitHub Actions setup. SafeERC20 reverts when a token explicitly returns `false`; the transaction rollback prevents the accounting update from persisting.

SafeERC20 also supports tokens that return no data, provided the low-level call succeeds. This compatibility behavior is not a guarantee that a token is honest, solvent, transferable, or economically safe.

## Reproduce the case

From the repository root:

```bash
forge install foundry-rs/forge-std --no-git
forge install OpenZeppelin/openzeppelin-contracts@v5.2.0 --no-git
forge test --match-path test/ERC20TransferReturn.t.sol -vv
```

The focused tests cover:
- a standard token transfer through both examples;
- a false-return token that causes the vulnerable example to record a payment that did not happen;
- a false-return token rejected by SafeERC20, with balances and accounting unchanged.

## Scope and limitations

These contracts and mocks are educational examples, not production payout systems and not a complete audit. A safe-transfer wrapper only addresses call/return handling. Review token-specific behavior such as fees, rebasing, callbacks, blacklists, pausing, upgradeability, privileged controls, and any assumptions made by the integrating protocol. Balance-delta accounting may be required for fee-on-transfer assets, depending on the application.

Do not treat a successful test or the use of SafeERC20 as proof that an arbitrary token integration is secure.
