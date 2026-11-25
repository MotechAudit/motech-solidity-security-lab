# Changelog

All notable changes to Motech Audit Solidity Security Lab are documented here.

This project uses Semantic Versioning (SemVer). Version tags use the `vMAJOR.MINOR.PATCH` format. This changelog is a human-readable summary; it is not a raw commit history.

## [Unreleased]

No unreleased changes have been recorded yet.

## [0.1.0] - 2026-11-26

Initial public release of the Motech Audit Solidity Security Lab.

### Added

- Educational native-asset vault examples demonstrating reentrancy and checks-effects-interactions.
- Access-control examples showing how an unrestricted privileged setter can redirect fee withdrawals, alongside an owner-restricted mitigation.
- `tx.origin` authorization examples comparing transaction-origin checks with immediate-caller authorization.
- ETH transfer-failure and empty-withdrawal regression tests.
- Fee-on-transfer ERC-20 accounting examples comparing requested-amount accounting with balance-delta accounting.
- ERC-20 compatibility examples using OpenZeppelin Contracts v5.6.1 `SafeERC20` and `forceApprove`, including optional-return and zero-first approval behavior.
- Delegatecall storage-collision examples with a safer normal-call comparison.
- Foundry unit and fuzz tests for the documented educational cases.
- Slither static-analysis workflow that publishes a SARIF report as a workflow artifact.
- Solidity external interface reference documenting constructors, external functions, inputs, outputs, public getters, access controls, state effects, custom errors, failure behavior, and event status.
- English-language README, contributing guide, community guide, code of conduct, security policy, and repository governance documentation.
- GitHub Actions workflows for Foundry tests, Slither analysis, OpenSSF Scorecard, and dependency updates.

### Validation

- Foundry tests are configured to run in GitHub Actions with 1,000 fuzz runs for each Foundry fuzz test.
- Slither analysis is run separately against the educational Solidity sources.
- A successful Slither workflow means the analysis completed; it does not mean that intentionally vulnerable fixtures have no findings or are secure.

### Upgrade and usage notes

- This is the project's initial tagged release; there is no earlier tagged release to migrate from.
- The repository is an educational security lab, not a production-ready contract library, wallet, vault, or complete audit.
- Contracts with names beginning with `Vulnerable` are intentionally insecure demonstrations and must not be deployed or used to hold real assets.
- The fixed examples demonstrate specific mitigations only. They do not provide a general security guarantee.
- ERC-20 examples depend on OpenZeppelin Contracts v5.6.1 where documented. Review token-specific behavior before reusing any example.
- Re-run the documented Foundry tests and review the Slither SARIF artifact when evaluating changes or adapting examples.

[Unreleased]: https://github.com/MotechAudit/motech-solidity-security-lab/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/MotechAudit/motech-solidity-security-lab/releases/tag/v0.1.0
