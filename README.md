# Motech Audit — Solidity Security Lab

[![Solidity Tests](https://github.com/MotechAudit/motech-solidity-security-lab/actions/workflows/solidity-tests.yml/badge.svg)](https://github.com/MotechAudit/motech-solidity-security-lab/actions/workflows/solidity-tests.yml)

A practical, test-first lab for understanding common smart-contract security mistakes and checking how a mitigation changes the behavior. Examples are intentionally educational and paired with reproducible Foundry tests.

**Useful to you?** Give the repository a ⭐ Star so more Solidity builders can find it. Found a gap? Open an Issue. Want to help improve it? Beginner-friendly contributions are welcome.

## Explore the lab

| Topic | What you can learn | Code and tests |
| --- | --- | --- |
| Reentrancy | How calling external code before updating accounting can expose a withdrawal path, and how checks-effects-interactions changes it | [VulnerableVault.sol](src/VulnerableVault.sol) · [FixedVault.sol](src/FixedVault.sol) · [Reentrancy.t.sol](test/Reentrancy.t.sol) |
| Access control | Why privileged state changes must enforce authorization | [VulnerableFeeVault.sol](src/access-control/VulnerableFeeVault.sol) · [FixedFeeVault.sol](src/access-control/FixedFeeVault.sol) · [AccessControl.t.sol](test/AccessControl.t.sol) · [Case notes](docs/access-control.md) |
| `tx.origin` authorization | Why authorizing with the original transaction initiator can trust the wrong caller | [VulnerableTxOriginWallet.sol](src/tx-origin/VulnerableTxOriginWallet.sol) · [FixedOwnerWallet.sol](src/tx-origin/FixedOwnerWallet.sol) · [TxOrigin.t.sol](test/TxOrigin.t.sol) · [Case notes](docs/tx-origin.md) |
| Failed ETH transfers | How reverted transfers should preserve vault balances and accounting | [TransferFailure.t.sol](test/TransferFailure.t.sol) |
| Vault accounting fuzzing | How fuzz tests can probe deposits, withdrawals, and per-user accounting invariants | [VaultAccountingFuzz.t.sol](test/VaultAccountingFuzz.t.sol) |
| Empty withdrawal edge cases | How reverts and per-user accounting protect other depositors' funds | [EmptyWithdrawal.t.sol](test/EmptyWithdrawal.t.sol) |

## Run the tests

Install [Foundry](https://getfoundry.sh/), then run from the repository root:

```bash
forge install foundry-rs/forge-std --no-git
forge test -vv
```

The dependency install is local; it does not need to be committed. GitHub Actions also runs the test suite on pushes and pull requests.

## Make your first contribution

You do not need to be a security expert to help. Pick one small task:

- **Testing / fuzzing:** [Issue #8 — Extend fuzz coverage across multiple deposits and users](https://github.com/MotechAudit/motech-solidity-security-lab/issues/8)
- **Documentation:** [Issue #5 — Write a beginner-friendly reentrancy walkthrough](https://github.com/MotechAudit/motech-solidity-security-lab/issues/5)

**Suggested path:** open an issue → comment that you would like to work on it → make a focused change → run `forge test -vv` → open a pull request. You can also [report a bug or suggest a test](https://github.com/MotechAudit/motech-solidity-security-lab/issues/new/choose) without submitting code.

Before contributing, read [CONTRIBUTING.md](CONTRIBUTING.md). For security-sensitive reports, follow our [Security Policy](SECURITY.md) instead of posting exploit details publicly.

Please do not submit customer code, confidential audit reports, private findings, secrets, API keys, or credentials.

## Scope and disclaimer

This is an educational repository, not a production-ready contract library and not a complete security audit. The examples are intentionally simplified. A passing test suite does not prove a contract is secure, and a mitigation shown here does not replace a context-specific review of external-call paths, access controls, accounting, dependencies, and business logic.

Do not deploy vulnerable examples or use these snippets to assess a production contract without an independent, context-specific review.

## About Motech Audit

Motech Audit researches smart-contract security and develops tools and learning resources to help Web3 teams understand and mitigate risk.
