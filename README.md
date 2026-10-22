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

## Run the tests

Install [Foundry](https://getfoundry.sh/), then run from the repository root:

```bash
forge install foundry-rs/forge-std --no-git
forge test -vv
```

The dependency install is local; it does not need to be committed. GitHub Actions also runs the test suite on pushes and pull requests.

## Help improve the lab

You do not need to be a security expert to make a useful contribution.

- **First contribution:** start with [Good first issue #4 — Add fuzz tests for vault accounting invariants](https://github.com/MotechAudit/motech-solidity-security-lab/issues/4). Read the acceptance criteria and comment before starting so duplicate work can be avoided.
- **Found a bug or missing test?** [Open an issue](https://github.com/MotechAudit/motech-solidity-security-lab/issues/new/choose). A clear reproduction or a suggested test is helpful; you do not need to submit code.
- **Have a fix or example?** Read [CONTRIBUTING.md](CONTRIBUTING.md), run `forge test -vv`, and open a focused pull request. Pair vulnerable behavior with a specific mitigation where relevant, and explain the limits of the example.
- **Just learning?** Star the repository if you find it useful, then explore a case and its test to see how the behavior is reproduced.

Good contributions include additional regression or fuzz tests, new self-contained educational examples, clearer case notes, and CI improvements. Small, verifiable pull requests are preferred.

Please do not submit customer code, confidential audit reports, private findings, secrets, API keys, or credentials.

## Scope and disclaimer

This is an educational repository, not a production-ready contract library and not a complete security audit. The examples are intentionally simplified. A passing test suite does not prove a contract is secure, and a mitigation shown here does not replace a context-specific review of external-call paths, access controls, accounting, dependencies, and business logic.

Do not deploy vulnerable examples or use these snippets to assess a production contract without an independent, context-specific review.

## About Motech Audit

Motech Audit researches smart-contract security and develops tools and learning resources to help Web3 teams understand and mitigate risk.
