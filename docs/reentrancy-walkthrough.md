# Reentrancy Walkthrough

A beginner-friendly guide to reproducing the reentrancy example in this repository and understanding what each test assertion demonstrates.

## What reentrancy is

Reentrancy happens when a contract sends ETH (or calls another contract) **before** it updates its own accounting. The recipient is a contract, so its `receive()` function runs while the first call is still in progress — and it can call back into the same function again, before the balance was cleared. Each re-entered call sees the old balance and withdraws again.

The fix is the **checks-effects-interactions** pattern: update state first, then make the external call.

## The vulnerable code

`src/VulnerableVault.sol` — `withdraw()` in the order it executes:

```solidity
uint256 amount = balances[msg.sender];          // 1. Check: read the balance
require(amount > 0, "Nothing to withdraw");

(bool success, ) = msg.sender.call{value: amount}("");  // 2. Interaction: send ETH FIRST
require(success, "Transfer failed");

balances[msg.sender] = 0;                       // 3. Effect: clear the balance AFTER
```

The external call at step 2 hands control to the recipient. If the recipient is a contract, its `receive()` runs immediately — and it can call `withdraw()` again. At that point `balances[msg.sender]` is still the original amount, because step 3 has not run yet. The second call withdraws the same amount again, and so on until the vault is empty.

## The fixed code

`src/FixedVault.sol` — same function, two lines swapped:

```solidity
uint256 amount = balances[msg.sender];          // 1. Check: read the balance
require(amount > 0, "Nothing to withdraw");

balances[msg.sender] = 0;                       // 2. Effect: clear the balance FIRST

(bool success, ) = msg.sender.call{value: amount}("");  // 3. Interaction: send ETH after
require(success, "Transfer failed");
```

Now a re-entered `withdraw()` reads `balances[msg.sender] == 0` and reverts on the `require(amount > 0)` check. The attacker gets its own deposit once and nothing more.

## Reproducing it locally

Run only the reentrancy tests (from the repository root):

```bash
forge test --match-contract ReentrancyTest -vv
```

Expected output — both tests pass:

```
[PASS] testVulnerableVaultCanBeDrainedByReentrancy()
[PASS] testFixedVaultPreventsRepeatedWithdrawalOfSameBalance()
```

Both tests pass because each one asserts the *expected* outcome for its vault: the vulnerable one is drained, the fixed one is not.

## What each test demonstrates

The tests live in `test/Reentrancy.t.sol`. A helper contract, `ReentrancyAttacker`, plays the role of the malicious recipient: its `receive()` calls `withdraw()` again while a withdrawal is in progress.

### `testVulnerableVaultCanBeDrainedByReentrancy`

Setup: the vault holds 10 ETH from an honest user; the attacker deposits 1 ETH of its own, then calls `withdraw()`.

What happens:

1. The attacker withdraws its 1 ETH. The vault sends the ETH, and the attacker's `receive()` fires before the balance is cleared.
2. `receive()` calls `withdraw()` again. The balance still reads 1 ETH, so the vault sends another 1 ETH. This repeats until the vault is empty.

Assertions:

- `address(vault).balance == 0` — the vault is fully drained.
- `address(attacker).balance == 11 ether` — the attacker ends up with its own 1 ETH plus the 10 ETH that belonged to the honest user.

### `testFixedVaultPreventsRepeatedWithdrawalOfSameBalance`

Same setup, but against `FixedVault`.

What happens:

1. The attacker withdraws its 1 ETH. The balance is cleared **before** the ETH is sent, so the re-entered `withdraw()` inside `receive()` reverts.
2. The `try/catch` in the attacker's `receive()` swallows that revert, and the original withdrawal completes normally.

Assertions:

- `address(vault).balance == 10 ether` — the honest user's funds stay put.
- `address(attacker).balance == 1 ether` — the attacker gets back only its own deposit.
- `vault.balances(address(attacker)) == 0` — the withdrawn balance is cleared.

## Key takeaway

The difference between the two vaults is **one ordering choice**: state update before the external call, not after. Reproducing a vulnerability like this shows *how* the attack works; it does not prove a system secure. A real audit also checks every other external call, access control, and edge case — this example is a single lesson, not a complete audit or a production-ready vault.

## Further reading

- Vulnerable example: [`src/VulnerableVault.sol`](../src/VulnerableVault.sol)
- Fixed example: [`src/FixedVault.sol`](../src/FixedVault.sol)
- Tests: [`test/Reentrancy.t.sol`](../test/Reentrancy.t.sol)
- Case notes: [`README.md`](../README.md) (reentrancy row)
