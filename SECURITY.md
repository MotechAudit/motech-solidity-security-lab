# Security Policy

## Scope

The Motech Audit Solidity Security Lab is an educational repository containing intentionally simplified contracts, vulnerability demonstrations, tests, documentation, and CI configuration.

The `Vulnerable*` examples are intentionally insecure by design. Their documented behavior is not, by itself, an unexpected vulnerability in the lab. Please report unintended issues in the examples, fixes, tests, workflows, or documentation that could mislead users or create risks beyond the documented educational purpose.

The `main` branch is the current development target. No security support is promised for historical commits or forks.

## Reporting a potential security issue

**Please do not publish vulnerability details in a public Issue, Discussion, or Pull Request.**

1. On the repository page, open **Security and quality** (or **Security**) → **Advisories** → **Report a vulnerability**, if private vulnerability reporting is available.
2. Include the affected file and commit or branch, the impact, clear reproduction steps, and any suggested mitigation.
3. Give the maintainers a reasonable opportunity to review the report before publicly discussing details.

If the **Report a vulnerability** option is not available, open an Issue with only the title **“Request for private security disclosure channel”**. Do not include exploit details, sensitive code, a proof of concept, credentials, or other confidential information in that public Issue. Wait for the maintainers to provide a private reporting route before sharing technical details.

For general bugs in the educational examples, docs, or test harness that are not security-sensitive, use the repository's normal Issue templates.

## Protect confidential information

Do not submit client code, confidential audit reports, private findings from third-party projects, secrets, API keys, or credentials. Do not use this educational repository to disclose an unpatched issue in a live third-party target.

## Educational limitations

This repository is not a production-ready contract library or a complete security audit. Tests and examples are intended to demonstrate specific behaviors; passing tests do not prove a contract is secure.
