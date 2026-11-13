# Unchecked ERC-20 transfer return values

## The wrong assumption

A common integration pattern is:

```solidity
token.transfer(recipient, amount);
paid[recipient] += amount;
```

It assumes every ERC-20 token either reverts on failure or returns `true`.
That assumption is false. The ERC-20 standard says `transfer` returns a
bool, but real tokens vary:

- **Standard tokens** return `true` and move the balance.
- **Some tokens return `false` instead of reverting** when the transfer
  cannot happen — and move nothing.
- **Legacy tokens** (for example, USDT on some chains) return **no data at
  all** from `transfer`.

If the caller ignores the return value, the first case silently corrupts
accounting: the contract records a payment that never happened, and the
user's earned balance is cleared even though they received nothing.

## The example

| File | Role |
| --- | --- |
| `src/erc20-transfer/VulnerableTokenPayout.sol` | Payout that calls `token.transfer(...)` and ignores the return value, then records the payment. |
| `src/erc20-transfer/FixedTokenPayout.sol` | Same payout, guarded by OpenZeppelin `SafeERC20`. |
| `src/erc20-transfer/MockTokens.sol` | Three mock tokens sharing the `transfer` selector with different return behavior: `StandardToken` (returns `true`), `FalseReturnToken` (returns `false`, moves nothing), `NoReturnToken` (returns no data). |
| `test/UncheckedERC20Transfer.t.sol` | Six tests proving whether balances actually moved. |

### What the tests prove

- **Vulnerable + false-return token:** `claim()` succeeds, `paid[user]`
  becomes the full reward, `earned[user]` is cleared — but the user's token
  balance stays `0` and the payout still holds the tokens. The reward is now
  unclaimable.
- **Vulnerable + standard token:** works fine. The bug only shows up with
  non-standard return behavior, which is why it survives code review.
- **Fixed + false-return token:** `safeTransfer` reverts with
  `SafeERC20FailedOperation`, accounting is untouched, and the user can still
  claim later.
- **Fixed + legacy no-return token:** `safeTransfer` tolerates the empty
  returndata and the payout succeeds.
- **Vulnerable + legacy no-return token:** the naive call through the
  `IERC20` interface reverts, because the ABI decoder expects a 32-byte
  bool. This failure is loud, not silent — but the payout still cannot serve
  legacy tokens at all.

## The fix

Use a safe-transfer wrapper instead of a raw `transfer` call. This example
uses OpenZeppelin `SafeERC20` (`safeTransfer`), which makes a low-level call
and then:

1. reverts if the call itself failed;
2. reverts with `SafeERC20FailedOperation` if the token returned `false`;
3. accepts an empty return (legacy no-return tokens) as success.

## Dependency

- **OpenZeppelin Contracts v5.0.2** — `SafeERC20` and `IERC20`.
  Install locally with:

  ```bash
  forge install OpenZeppelin/openzeppelin-contracts@v5.0.2 --no-git
  ```

  The GitHub Actions workflows install the same pinned version, so CI
  reproduces the local build. The dependency lives under `lib/` and is not
  committed (see `.gitignore`).

## Assumptions and limits

- `SafeERC20` checks the transfer's return value; it does **not** make an
  arbitrary or malicious token trustworthy. A token can still misbehave in
  other ways (fake balances, fee-on-transfer, callbacks, upgradeable logic
  that changes behavior later).
- For high-value integrations, verify the actual balance change
  (`balanceOf` before and after) instead of trusting any return value.
- This example covers the three return behaviors above. It does not cover
  every non-standard token behavior in the wild.
- The payout contracts have no access control on `credit()` on purpose:
  they are minimal teaching fixtures, not production distributors.
  **Do not deploy them.**
