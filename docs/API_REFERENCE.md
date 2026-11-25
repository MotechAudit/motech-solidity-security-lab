# Solidity External Interface Reference

This document describes the externally callable ABI of the educational contracts in `src/` on the repository's `main` branch. It is a reference for the examples, not a deployment guide or a claim that any example is production-ready.

- Solidity compiler configured by `foundry.toml`: **0.8.20**.
- Unless stated otherwise, functions return no ABI data.
- A public state variable or public mapping automatically exposes a getter; those getters are listed below.
- None of the contracts in `src/` declares an event.
- The deliberately vulnerable contracts are included only to demonstrate specific mistakes. **Do not deploy them or use them to hold real assets.**
- Foundry test helpers and mock tokens under `test/` are test fixtures, not supported project interfaces, and are not included as production interfaces here.

## 1. Native-asset vault examples

### `VulnerableVault` — `src/VulnerableVault.sol`

Educational reentrancy-vulnerable ETH vault.

**Constructor**
- No parameters.
- Sets no owner or other initial state.

| External interface | Inputs | Outputs | Access and state effects |
|---|---|---|---|
| `deposit()` | `msg.value`: ETH amount sent with the call | None | Payable; any caller. Adds `msg.value` to the caller's `balances`. |
| `withdraw()` | None | None | Any caller; sends the caller's recorded ETH balance to the caller. Intentionally performs the external call before clearing the recorded balance, demonstrating reentrancy. |

**Public getter**
- `balances(address account) → uint256`: recorded ETH balance for `account`.

**Failure behavior**
- `withdraw()` reverts with `"Nothing to withdraw"` when the caller has no recorded balance.
- It reverts with `"Transfer failed"` if the ETH transfer fails. A failed transaction rolls back state changes.

### `FixedVault` — `src/FixedVault.sol`

Educational comparison using checks-effects-interactions.

| External interface | Inputs | Outputs | Access and state effects |
|---|---|---|---|
| `deposit()` | `msg.value`: ETH amount sent with the call | None | Payable; any caller. Adds `msg.value` to the caller's `balances`. |
| `withdraw()` | None | None | Any caller; reads and clears the caller's recorded balance before sending ETH to the caller. |

**Public getter**
- `balances(address account) → uint256`: recorded ETH balance for `account`.

**Failure behavior**
- Reverts with `"Nothing to withdraw"` if the caller has no recorded balance.
- Reverts with `"Transfer failed"` if the recipient rejects ETH or the transfer otherwise fails; the transaction rollback restores the previous accounting.

## 2. Fee-vault access-control examples

### `VulnerableFeeVault` — `src/access-control/VulnerableFeeVault.sol`

Intentionally lacks authorization on `setFeeRecipient()`.

**Constructor**
- `initialFeeRecipient: address`: initial address that receives accrued fees. Must not be the zero address.
- Sets `owner` to the deploying address.

| External interface | Inputs | Outputs | Access and state effects |
|---|---|---|---|
| `fund()` | `msg.value`: ETH amount to add to accrued fees | None | Payable; any caller. Increases `accruedFees`. |
| `setFeeRecipient(address newRecipient)` | `newRecipient`: new fee recipient; cannot be zero | None | **Intentionally permissionless**. Any caller can redirect future fee withdrawals. |
| `withdrawFees()` | None | None | Owner only. Sets accrued fees to zero, then sends the amount to `feeRecipient`. |

**Public getters**
- `owner() → address`
- `feeRecipient() → address`
- `accruedFees() → uint256`

**Custom errors**
- `InvalidRecipient()`: constructor or setter receives the zero address.
- `NothingToWithdraw()`: no fees have accrued.
- `TransferFailed()`: ETH transfer to the recipient fails.
- `Unauthorized()`: caller is not the owner of `withdrawFees()`.

### `FixedFeeVault` — `src/access-control/FixedFeeVault.sol`

Mitigated comparison; fee-recipient changes and fee withdrawals are owner-only.

**Constructor**
- `initialFeeRecipient: address`: initial fee recipient; cannot be zero.
- Sets `owner` to the deploying address.

| External interface | Inputs | Outputs | Access and state effects |
|---|---|---|---|
| `fund()` | `msg.value`: ETH amount to add to accrued fees | None | Payable; any caller. Increases `accruedFees`. |
| `setFeeRecipient(address newRecipient)` | `newRecipient`: non-zero fee recipient | None | Owner only. Updates `feeRecipient`. |
| `withdrawFees()` | None | None | Owner only. Clears `accruedFees` then sends the amount to `feeRecipient`. |

**Public getters**
- `owner() → address`
- `feeRecipient() → address`
- `accruedFees() → uint256`

**Custom errors**
- `InvalidRecipient()`, `NothingToWithdraw()`, `TransferFailed()`, `Unauthorized()` as described above.

## 3. `tx.origin` authorization examples

### `VulnerableTxOriginWallet` — `src/tx-origin/VulnerableTxOriginWallet.sol`

Intentionally demonstrates why `tx.origin` is unsafe as the authorization identity.

**Constructor**
- No parameters.
- Sets `owner` to the deploying address.

| External interface | Inputs | Outputs | Access and state effects |
|---|---|---|---|
| `receive()` | ETH via an empty-calldata transfer | None | Payable; accepts ETH from any sender. |
| `withdrawTo(address payable recipient, uint256 amount)` | `recipient`: destination address; `amount`: ETH amount in wei | None | Checks `tx.origin == owner`, not the immediate caller. This is intentionally vulnerable to a malicious intermediary when the owner is induced to interact with it. |

**Public getter**
- `owner() → address`.

**Custom errors**
- `Unauthorized()`: `tx.origin` is not the owner.
- `TransferFailed()`: sending ETH fails.

### `FixedOwnerWallet` — `src/tx-origin/FixedOwnerWallet.sol`

Comparison that checks the immediate caller.

**Constructor**
- No parameters.
- Sets `owner` to the deploying address.

| External interface | Inputs | Outputs | Access and state effects |
|---|---|---|---|
| `receive()` | ETH via an empty-calldata transfer | None | Payable; accepts ETH from any sender. |
| `withdrawTo(address payable recipient, uint256 amount)` | `recipient`: non-zero destination; `amount`: ETH amount in wei | None | Owner only, based on `msg.sender`; sends ETH to the recipient. |

**Public getter**
- `owner() → address`.

**Custom errors**
- `Unauthorized()`: caller is not the owner.
- `InvalidRecipient()`: recipient is the zero address.
- `TransferFailed()`: sending ETH fails, including insufficient wallet balance.

## 4. Delegatecall storage examples

### `StorageCollisionModule` — `src/delegatecall/StorageCollisionModule.sol`

Small module whose `value` occupies storage slot 0.

| External interface | Inputs | Outputs | Access and state effects |
|---|---|---|---|
| `setValue(uint256 newValue)` | `newValue`: value to store | None | Any caller; writes the module's own `value` when called normally. Under delegatecall, writes to the caller's storage context. |

**Public getter**
- `value() → uint256`.

### `VulnerableDelegateCaller` — `src/delegatecall/VulnerableDelegateCaller.sol`

Intentionally demonstrates a delegatecall storage collision. The caller's `owner` occupies slot 0, as does the module's `value`.

**Constructor**
- No parameters.
- Sets `owner` to the deploying address.

| External interface | Inputs | Outputs | Access and state effects |
|---|---|---|---|
| `delegateSetValue(address module, uint256 newValue)` | `module`: module address; `newValue`: value encoded for `setValue(uint256)` | None | Owner only. Delegatecalls the supplied module; because slot layouts differ, the module write can overwrite the caller's `owner`. |

**Public getter**
- `owner() → address`.

**Custom errors**
- `Unauthorized()`: caller is not the owner.
- `DelegateCallFailed(bytes reason)`: delegatecall returns failure; `reason` contains returned revert data.

### `FixedExternalCaller` — `src/delegatecall/FixedExternalCaller.sol`

Safer comparison using a normal external call rather than delegatecall.

**Constructor**
- No parameters.
- Sets `owner` to the deploying address.

| External interface | Inputs | Outputs | Access and state effects |
|---|---|---|---|
| `callModule(address module, uint256 newValue)` | `module`: target module; `newValue`: value passed to `setValue(uint256)` | None | Owner only. Uses a normal `call`; the module updates its own storage, not the caller's storage. |

**Public getter**
- `owner() → address`.

**Custom errors**
- `Unauthorized()`: caller is not the owner.
- `ExternalCallFailed(bytes reason)`: normal call fails; `reason` contains returned revert data.

## 5. ERC-20 examples

### `IERC20Minimal` — `src/erc20/IERC20Minimal.sol`

Minimal interface used by the fee-on-transfer examples.

| Interface function | Inputs | Outputs |
|---|---|---|
| `balanceOf(address account)` | Account address | `uint256` token balance |
| `transfer(address to, uint256 amount)` | Recipient and token amount | `bool` success indicator |
| `transferFrom(address from, address to, uint256 amount)` | Source, recipient, token amount | `bool` success indicator |

This is a deliberately minimal interface, not a replacement for the complete ERC-20 interface.

### `VulnerableFeeOnTransferVault` — `src/erc20/VulnerableFeeOnTransferVault.sol`

Intentionally credits the requested amount even if a fee-on-transfer token delivers less.

**Constructor**
- `token_: IERC20Minimal`: token contract used for deposits and withdrawals.

| External interface | Inputs | Outputs | Access and state effects |
|---|---|---|---|
| `deposit(uint256 requestedAmount)` | Requested token amount; must be greater than zero | None | Any caller. Calls `transferFrom`, then credits the requested amount rather than the amount actually received. |
| `withdraw()` | None | None | Any caller; clears caller's credit and transfers that nominal amount of tokens. |

**Public getters**
- `token() → address`
- `credits(address account) → uint256`
- `totalCredits() → uint256`

**Failure behavior**
- `"Zero amount"` if the requested amount is zero.
- `"Transfer failed"` if `transferFrom` or `transfer` returns false.
- `"Nothing to withdraw"` if no credit exists.
- Token contract reverts are propagated.

### `FixedFeeOnTransferVault` — `src/erc20/FixedFeeOnTransferVault.sol`

Credits the amount received, measured using the vault token-balance difference.

**Constructor**
- `token_: IERC20Minimal`: token contract used for deposits and withdrawals.

| External interface | Inputs | Outputs | Access and state effects |
|---|---|---|---|
| `deposit(uint256 requestedAmount)` | Requested token amount; must be greater than zero | None | Any caller. Measures balance before and after `transferFrom`, then credits the received amount. |
| `withdraw()` | None | None | Any caller; clears caller's credit before transferring tokens. |

**Public getters**
- `token() → address`
- `credits(address account) → uint256`
- `totalCredits() → uint256`

**Custom errors**
- `ZeroAmount()`: zero deposit or no withdrawable credit / zero received amount.
- `TransferFailed()`: token transfer returns false.
- Token contract reverts are propagated.

### `SafeERC20CompatibilityVault` — `src/erc20/SafeERC20CompatibilityVault.sol`

Uses OpenZeppelin Contracts v5.6.1 `SafeERC20` to handle common ERC-20 optional-return behavior.

**Constructor**
- `token_: IERC20`: ERC-20 token contract.

| External interface | Inputs | Outputs | Access and state effects |
|---|---|---|---|
| `deposit(uint256 requestedAmount)` | Requested token amount | None | Any caller. Uses `safeTransferFrom`, measures the balance delta and credits the amount received. |
| `withdraw()` | None | None | Any caller; clears caller credit and uses `safeTransfer` to send the credited amount. |

**Public getters**
- `token() → address`
- `credits(address account) → uint256`
- `totalCredits() → uint256`

**Custom error**
- `ZeroReceived()`: the deposit produces no positive balance increase, or the caller has no credit to withdraw.

**Other failure behavior**
- OpenZeppelin `SafeERC20` reverts for an unsuccessful token operation, including an explicit false return. Underlying token reverts are propagated or wrapped according to the library implementation.
- Checked arithmetic can revert if the observed balance decreases between the before/after reads.

### `SafeAllowanceManager` — `src/erc20/SafeAllowanceManager.sol`

Owner-controlled example using OpenZeppelin `SafeERC20.forceApprove`.

**Constructor**
- `token_: IERC20`: token whose allowance is managed.
- `owner_: address`: address authorized to set the spender allowance.

| External interface | Inputs | Outputs | Access and state effects |
|---|---|---|---|
| `setSpenderAllowance(address spender, uint256 amount)` | Spender address and allowance amount | None | Only the configured `owner`; calls `forceApprove` on the token. This supports tokens requiring a non-zero allowance to be reset to zero before another non-zero value is set. |

**Public getters**
- `token() → address`
- `owner() → address`

**Custom error**
- `Unauthorized()`: caller differs from the configured owner.

**Other failure behavior**
- Failures from the token or OpenZeppelin `SafeERC20.forceApprove` are propagated according to the library implementation.

## Events and ABI notes

- The contracts listed above declare **no events** in their current source.
- The functions listed as returning “None” have no ABI return data.
- Public state variables and mappings expose the getter functions listed for each contract.
- Solidity custom errors are part of the ABI and are listed where declared.
- Compiler-generated ABI details should be regenerated from the exact source revision when integrating these examples; this prose reference is not a substitute for the compiler-generated ABI JSON.

## Scope and limitations

This reference documents the source contracts currently under `src/`. It does not define a stable production API or promise backward compatibility between educational examples. The vulnerable fixtures intentionally contain the flaw being demonstrated. The fixed fixtures demonstrate only the specific mitigation described; they are not production-ready contracts and are not a substitute for a complete audit.

For the source code, tests, and build configuration, see the [repository README](../README.md), [Foundry tests](../test/), and [foundry.toml](../foundry.toml).
