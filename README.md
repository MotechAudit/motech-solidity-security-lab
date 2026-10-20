# Motech Audit — Solidity Security Lab

Open-source Solidity security examples, reproducible tests, and developer learning resources maintained by Motech Audit.

## What's inside

- **Reentrancy example** — a deliberately vulnerable ETH vault and a minimal mitigation example.
- **Regression tests** — Foundry tests demonstrating the issue and validating the specific behavior shown by the fix.
- **Continuous integration** — GitHub Actions runs the test suite on pushes and pull requests.

## Quick start

Install [Foundry](https://getfoundry.sh/), then run from the repository root:

```bash
forge install foundry-rs/forge-std --no-git
forge test -vv
```

The first command installs the Foundry test helpers locally. It does not need to be committed.

## Learning example: reentrancy

- [VulnerableVault.sol](src/VulnerableVault.sol)
- [FixedVault.sol](src/FixedVault.sol)
- [Reentrancy.t.sol](test/Reentrancy.t.sol)

The vulnerable example makes an external call before updating its accounting. The mitigation example follows checks-effects-interactions by clearing the caller's recorded balance before transferring ETH.

## Access-control example

- [VulnerableFeeVault.sol](src/access-control/VulnerableFeeVault.sol) — intentionally omits authorization on a privileged setter.
- [FixedFeeVault.sol](src/access-control/FixedFeeVault.sol) — restricts fee-recipient changes to the owner.
- [AccessControl.t.sol](test/AccessControl.t.sol) — demonstrates unauthorized fee redirection and tests the fix.
- [Case notes](docs/access-control.md) — impact, mitigation, and limitations.

## Contribute

We welcome focused contributions: new vulnerability examples, tests that reproduce a concrete security property, clearer remediation notes, and CI improvements.

- Start with [Good first issue #1: Access-control vulnerability example](https://github.com/MotechAudit/motech-solidity-security-lab/issues/1).
- Read [CONTRIBUTING.md](CONTRIBUTING.md) before opening a pull request.
- Report a bug or suggest an improvement using the repository's **Issues** tab.

Please do not submit customer code, confidential audit reports, private findings, secrets, or API keys.

## Scope and disclaimer

This is an educational repository, not a production-ready contract library and not a complete security audit. The examples are intentionally simplified. A passing test suite does not prove a contract is secure, and the mitigation shown here does not replace a full review of external-call paths, access controls, accounting, dependencies, and business logic.

Do not deploy the vulnerable example or use these snippets to assess a production contract without an independent, context-specific review.

## About Motech Audit

Motech Audit researches smart-contract security and develops tools and learning resources to help Web3 teams understand and mitigate risk.
