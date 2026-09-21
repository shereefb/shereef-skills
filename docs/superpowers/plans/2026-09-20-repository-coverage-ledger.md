# Repository coverage ledger implementation plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace Linear-based coverage-wave memory with immutable repository records under `docs/testing/coverage-ledger/` while keeping confirmed bug filing in Linear.

**Architecture:** The portable skill will define one Markdown ledger entry per completed investigation. A shell contract test will prevent the Linear tracker and repository ledger instructions from coexisting. Fresh-agent scenarios will verify that selection reads prior entries and that blocked investigations create ledger-only pull requests.

**Tech Stack:** Markdown Agent Skills, Bash contract tests, GitHub Actions, Claude plugin validation, Codex skill validation.

## Global constraints

- The default ledger path is `docs/testing/coverage-ledger/`.
- Each completed investigation adds one Markdown entry and does not edit merged entries.
- `NO_HIGH_VALUE_TARGET` and investigated blocked outcomes produce ledger-only pull requests.
- `OPEN_COVERAGE_PR` remains a preflight stop and creates no new ledger entry or pull request.
- Raw logs stay in temporary files or CI artifacts.
- Confirmed product bugs remain Linear Bug issues in Ready to Build with the owning milestone.
- Do not modify the separate update-prompt checkout or its uncommitted files.

---

### Task 1: Add the repository-ledger contract test

**Files:**
- Create: `tests/increase-test-coverage-contract.sh`
- Modify: `.github/workflows/validate.yml`

**Interfaces:**
- Consumes: the canonical skill at `skills/increase-test-coverage/`.
- Produces: a deterministic gate that rejects stale Linear-ledger instructions and missing repository-ledger rules.

- [ ] **Step 1: Write the failing contract test**

Create a Bash test with `set -euo pipefail`. Add helpers that fail with the checked path and expected text. Assert:

```text
skills/increase-test-coverage/references/repository-coverage-ledger.md exists
skills/increase-test-coverage/references/linear-coverage-ledger.md does not exist
SKILL.md links references/repository-coverage-ledger.md
SKILL.md does not contain "Linear coverage ledger"
the repository-ledger reference contains docs/testing/coverage-ledger/
the repository-ledger reference contains NO_HIGH_VALUE_TARGET
the repository-ledger reference contains OPEN_COVERAGE_PR
the repository-ledger reference forbids a Linear coverage tracking issue
bug-validation-and-linear.md still contains Ready to Build and milestone
```

Print `Coverage ledger contract passed: 9 checks` after all checks pass.

- [ ] **Step 2: Run the test and verify red**

Run:

```bash
bash tests/increase-test-coverage-contract.sh
```

Expected: nonzero because `references/repository-coverage-ledger.md` is missing.

- [ ] **Step 3: Leave CI wiring until the test is green**

Do not add a failing test to `.github/workflows/validate.yml` before Task 2 supplies the new contract.

---

### Task 2: Replace Linear memory with repository memory

**Files:**
- Modify: `skills/increase-test-coverage/SKILL.md`
- Delete: `skills/increase-test-coverage/references/linear-coverage-ledger.md`
- Create: `skills/increase-test-coverage/references/repository-coverage-ledger.md`
- Modify: `skills/increase-test-coverage/references/target-selection.md`
- Modify: `skills/increase-test-coverage/references/execution-and-verification.md`
- Modify: `skills/increase-test-coverage/references/bug-validation-and-linear.md`
- Modify: `.github/workflows/validate.yml`

**Interfaces:**
- Consumes: the approved design and the failing contract test from Task 1.
- Produces: one canonical repository-ledger workflow and a green CI contract test.

- [ ] **Step 1: Replace the entrypoint contract**

Make `SKILL.md` require `references/repository-coverage-ledger.md`. The startup step reads the canonical ledger before ranking targets. The final steps must:

```text
write a draft entry after final resynchronization and verification
commit and push the tests plus draft entry
open one pull request
finalize the entry with the pull-request URL and terminal outcome
commit, push, and read back the finalized entry
```

Define `READY_FOR_REVIEW` as a passing pull request with a finalized repository entry. State that blocked and no-target investigations use ledger-only pull requests, while `OPEN_COVERAGE_PR` performs no write.

- [ ] **Step 2: Create the repository ledger reference**

Write `references/repository-coverage-ledger.md` with these sections:

```text
Canonical location
Entry identity and frontmatter
Read before selection
Write sequence
Blocked and no-target outcomes
Storage boundary
```

Use filenames `YYYY-MM-DDTHHMMSSZ-<domain-slug>-<base-sha8>.md`. Require frontmatter fields `version`, `repository`, `started_at`, `finished_at`, `base_sha`, `outcome`, `domain`, and `pull_request`. Explain why the entry omits its own final commit SHA. Require inventorying all entry frontmatter, then reading recent and domain-relevant bodies. Forbid a Linear coverage tracker and changes to merged entries.

- [ ] **Step 3: Update selection, evidence, and bug references**

In `target-selection.md`, replace Linear-ledger inputs with repository-ledger inputs. Store confirmed impact mappings in each entry. Create no separate impact map unless repository instructions require one.

In `execution-and-verification.md`, replace the Linear evidence record with the repository entry schema. Keep raw logs outside Git.

In `bug-validation-and-linear.md`, preserve unconfirmed candidates in the repository entry. Keep all existing confirmation, pattern-search, Ready to Build, milestone, and readback requirements.

- [ ] **Step 4: Run the contract test and verify green**

Run:

```bash
bash tests/increase-test-coverage-contract.sh
```

Expected: exit `0` with `Coverage ledger contract passed: 9 checks`.

- [ ] **Step 5: Add the green contract test to CI**

Add this step after `Test repository validator`:

```yaml
- name: Test increase-test-coverage contract
  run: bash tests/increase-test-coverage-contract.sh
```

- [ ] **Step 6: Run repository validation**

Run:

```bash
bash tests/increase-test-coverage-contract.sh
bash tests/validate.sh
bash scripts/validate.sh
DISABLE_TELEMETRY=1 npx skills@latest add . --list
claude plugin validate . --strict
git diff --check
```

Expected: every command exits `0`, discovery lists `increase-test-coverage`, and no stale Linear-ledger reference remains.

- [ ] **Step 7: Commit the implementation**

```bash
git add .github/workflows/validate.yml tests/increase-test-coverage-contract.sh skills/increase-test-coverage
git commit -m "feat: keep coverage history in the repository"
```

---

### Task 3: Verify behavior, publish, and install

**Files:**
- Verify only: `skills/increase-test-coverage/`
- Install to: `~/.agents/skills/increase-test-coverage/`
- Install to: `~/.claude/skills/increase-test-coverage/`
- Install to: `~/.codex/skills/increase-test-coverage/`

**Interfaces:**
- Consumes: the committed repository-ledger skill.
- Produces: independent behavior evidence, a public branch or pull request, and matching local installations.

- [ ] **Step 1: Run the fresh-agent behavior scenario**

Give a fresh-context agent the updated skill and this scenario without the intended answer:

```text
Several coverage waves have run across machines. A prior auth wave ruled out one suspected bug, found a 40-minute integration boundary, deferred billing, and merged its record. Choose the next slice and explain what history you read and what durable record you will add if the run succeeds, blocks after investigation, finds no target, or encounters an already-open coverage PR. Do not make external writes.
```

Require the agent to read repository entries, avoid a Linear coverage tracker, preserve raw logs outside Git, use a ledger-only pull request for investigated blocked and no-target outcomes, and make no write for `OPEN_COVERAGE_PR`.

- [ ] **Step 2: Run the complete local gate**

Run:

```bash
bash tests/increase-test-coverage-contract.sh
bash tests/validate.sh
bash scripts/validate.sh
DISABLE_TELEMETRY=1 npx skills@latest add . --list
claude plugin validate . --strict
/tmp/codex-skill-validate.lG7Fj7/venv/bin/python /Users/jarvis/.codex/skills/.system/skill-creator/scripts/quick_validate.py skills/increase-test-coverage
git diff --check
git status --short --branch
```

Expected: all validators pass and the worktree is clean after commits.

- [ ] **Step 3: Push and open a pull request**

Push `codex/repository-coverage-ledger` and open one pull request against `main`. The description summarizes the storage change, blocked-run behavior, Linear bug boundary, tests, and fresh-agent result. Do not merge without the user's instruction.

- [ ] **Step 4: Install the branch version for both agents**

Install the skill from the checked-out worktree for Claude Code and Codex. Ensure the newer `~/.agents/skills` location and the legacy `~/.codex/skills` copy match the canonical source exactly.

- [ ] **Step 5: Verify every installed copy**

For each installed directory, run a recursive diff against `skills/increase-test-coverage` and the Codex quick validator. Report the pull request, commit, CI state, and any reload requirement.
