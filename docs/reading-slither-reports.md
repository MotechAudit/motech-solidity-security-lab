# Reading Slither Reports

This guide explains how to find, open, and interpret the Slither static-analysis report produced by this repository's GitHub Actions workflow. It is written for first-time contributors who have never read a SARIF report before.

## Where the report lives

Every push and pull request runs the **Slither Static Analysis** workflow (`.github/workflows/slither-analysis.yml`). The workflow:

1. Installs Foundry and Slither 0.11.6.
2. Compiles only the production examples under `src/` (tests and scripts are excluded from the analysis build).
3. Runs Slither and writes the results to `slither-results.sarif`.
4. Uploads that file as a workflow artifact named **`slither-static-analysis-report`**, kept for 30 days.

To download it:

1. Open the **Actions** tab of the repository.
2. Click the **Slither Static Analysis** workflow run you want to inspect.
3. Scroll to the **Artifacts** section at the bottom of the run page.
4. Download **`slither-static-analysis-report`**. It contains a single file, `slither-results.sarif`.

## What SARIF is

SARIF (Static Analysis Results Interchange Format) is a JSON format for static-analysis output. One file holds every finding from a run, each with:

- **rule** — the detector that fired (for example `reentrancy-eth`, `tx-origin`, `uninitialized-state`), including a short description and a link to the detector documentation.
- **level** — severity: `error`, `warning`, or `note`.
- **locations** — the exact file, line, and column for each piece of code involved in the finding.
- **message** — a one-line explanation of what the detector saw.

You can read the JSON directly in any text editor, but it is much easier with a viewer:

- **VS Code** — install the Microsoft **SARIF Viewer** extension, then open the `.sarif` file. Findings appear in a list; clicking one jumps to the flagged code.
- **GitHub code scanning** — if a repository uploads SARIF to code scanning, findings appear under the **Security** tab. (This repository currently uploads the report as an artifact instead, so use the download steps above.)

## How to read a finding

Work through one finding at a time:

1. **Read the rule name and message first.** It tells you which pattern Slither matched, for example "reentrancy" or "use of `tx.origin` for authorization".
2. **Open the flagged location.** Read the surrounding function, not just the flagged line. A finding is only real if the flagged code can actually be reached in a harmful way.
3. **Check the related locations.** Some findings list several locations (for example, where a value is set and where it is used). Follow the chain before deciding.
4. **Decide the verdict:**
   - **True positive** — the code really has the weakness described.
   - **False positive** — the detector matched the pattern, but the code is safe (for example, a guard elsewhere prevents the dangerous path).
   - **Expected / intentional** — the code is deliberately vulnerable. See the note below.
5. **Confirm with a test when it matters.** A finding that claims funds can be drained should be backed by a Foundry test that reproduces the behavior (`forge test -vv`). If you cannot reproduce it, say so in your review instead of guessing.

## Why findings need human triage

Slither is a pattern matcher, not a judge. It flags code that *looks* like a known weakness. It does not know the intent of the code, and it cannot tell whether an external caller can actually reach the flagged path. That is why the workflow runs Slither with `--fail-none`: the workflow checks that the analyzer runs, it does not block on findings. A human reviewer decides what each finding means.

Two common reasons a finding is not a real problem here:

- **False positives.** The detector saw the pattern but missed a guard, a check, or a constraint that makes the code safe.
- **Intentional vulnerabilities.** This repository is a security lab. Files such as `src/VulnerableVault.sol` are deliberately vulnerable so readers can learn the weakness and its fix (compare with `src/FixedVault.sol`). A finding on an intentionally vulnerable example is expected, not a new bug. Do not report it as one.

## Reproducing the report locally

You can run the same analysis on your own machine before opening a pull request:

```bash
# From the repository root. Requires Foundry and Python 3.10+.
forge clean
forge build --build-info --skip test script --force
slither . --ignore-compile --sarif slither-results.sarif --fail-none --disable-color
```

Then open `slither-results.sarif` in the SARIF Viewer as described above. Running it locally is the fastest way to check whether a change you made introduces a new finding, or clears one that was there before.

## Quick checklist for reviewers

- [ ] I downloaded the `slither-static-analysis-report` artifact for the run.
- [ ] I read the rule name and message before looking at the code.
- [ ] I checked whether the flagged code is reachable and harmful.
- [ ] I marked intentional findings on the educational examples as expected.
- [ ] I reproduced any finding I claim is real with a test or a clear explanation of the exploit path.
