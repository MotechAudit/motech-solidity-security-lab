# Repository Governance

This document describes the intended maintenance controls for the Motech Audit Solidity Security Lab. It distinguishes repository files and workflows from GitHub settings that must be enabled by a repository administrator.

## Maintainer ownership

- `.github/CODEOWNERS` identifies `@MotechAudit` as the code owner.
- Code owners are automatically requested for review when a pull request changes owned files.
- Code-owner approval is only a merge requirement when the repository's branch ruleset explicitly requires it.

## Recommended rules for the `main` branch

Configure these controls in **Settings → Rules → Rulesets** for the default branch:

1. Require changes to be submitted through a pull request.
2. Require at least one approving review from someone other than the pull request author. Add the code-owner review requirement when an independent reviewer is available.
3. Dismiss stale approvals when new commits change the reviewed diff.
4. Require all review conversations to be resolved before merging.
5. Require these status checks:
   - `Foundry tests`
   - `Slither analysis`
6. Block force pushes and branch deletion.
7. Keep bypass permissions narrow and documented.

A `CODEOWNERS` file alone does not enforce approvals. The corresponding ruleset must be enabled in GitHub settings.

## Security settings to enable

In **Settings → Security & quality → Advanced Security**, administrators should:

- Enable **Private vulnerability reporting** so researchers have a private route to disclose vulnerabilities. A `SECURITY.md` file by itself does not enable GitHub's private reporting form.
- Enable **Dependabot alerts**.
- Enable **Dependabot security updates**, where available.
- Review secret-scanning availability and enable it for this public repository if offered.

The repository's existing [Security Policy](../SECURITY.md) describes what to include in a report and prohibits public disclosure of sensitive exploit details.

## Automated checks in this repository

| Control | Purpose |
| --- | --- |
| Foundry tests | Reproduce expected and vulnerable behavior, including fuzz tests |
| Slither | Static analysis of the Solidity examples |
| OpenSSF Scorecard | Automated checks of selected repository security practices |
| Dependabot | Weekly update pull requests for GitHub Actions dependencies |
| CODEOWNERS | Identify the maintainer responsible for reviewing changes |

Scorecard results are an automated snapshot of selected repository practices. They are not an audit, certification, endorsement, or guarantee that the source code is secure.

## Review and release discipline

- Keep pull requests focused and explain the security impact, assumptions, and limitations.
- Do not merge solely because CI is green. Review test quality, changed files, dependency changes, and Slither findings.
- Treat intentionally vulnerable examples as educational fixtures, not production-ready code.
- Keep customer code, private audit reports, credentials, and non-public findings out of this repository.
- Publish tagged releases only after the main-branch checks pass and the release notes describe the included changes.

## Status transparency

Repository files and workflow definitions can be reviewed publicly. Branch rulesets, private reporting, Dependabot alerts, and other account-level security settings are separate GitHub configuration. Do not claim those settings are enabled until an administrator verifies them in the repository's Settings page.
