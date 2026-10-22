# Contributing

Thanks for helping improve the Motech Audit Solidity Security Lab. The goal is to make smart-contract security lessons practical, reproducible, and easy for other developers to verify.

## A simple first contribution

1. Pick a task from the repository's [open issues](https://github.com/MotechAudit/motech-solidity-security-lab/issues), ideally one marked **good first issue**.
2. Comment on the issue before starting so we can avoid duplicate work and clarify the intended scope.
3. Keep the change focused. Link the relevant contract, test, or documentation.
4. Run `forge test -vv` locally and include the result in your pull request.
5. Open a pull request explaining what changed, why it matters, and how you verified it.

Not every contribution needs to add code. Clear reproduction steps, documentation improvements, and focused test cases are useful contributions too.

## What makes a good contribution?

- Add a small, self-contained vulnerability example with a reproducible test.
- Pair vulnerable behavior with the specific mitigation being demonstrated, where relevant.
- Explain impact, preconditions, and limitations in plain language.
- Add tests that assert observable behavior and relevant state changes.
- Improve CI or developer instructions in a way another contributor can verify.

## Pull request checklist

- [ ] The change has a clear, limited scope.
- [ ] Intentionally vulnerable examples are clearly labeled and must not be presented as production-ready.
- [ ] Tests reproduce the behavior being described.
- [ ] The mitigation's scope and limitations are documented where relevant.
- [ ] `forge test -vv` passes locally.
- [ ] No customer code, private audit reports, credentials, or secrets are included.

## Security and disclosure

Do not submit client-confidential code, private audit reports, credentials, or live exploitable details about an unpatched third-party target. For sensitive disclosures, use the project's designated private contact channel rather than a public issue.

## Important

This repository is for education and reproducible examples. Inclusion here does not represent a certification, audit result, or guarantee of security.
