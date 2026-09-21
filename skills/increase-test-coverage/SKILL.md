---
name: increase-test-coverage
description: Use when a repository needs a strategic test-coverage wave, especially when high-churn or high-consequence behavior is weakly tested and slow integration or end-to-end suites make broad iteration impractical.
---

# Increase test coverage

Run one bounded coverage wave. Improve confidence in important behavior, not the percentage alone. Produce at most one pull request, then stop. An outer loop may invoke the skill again after that pull request lands and `main` changes.

## Required constraints

- Start a fresh isolated worktree from the fetched `origin/main`. Do not alter the main checkout. Report any necessary base-branch substitution.
- Stop when another coverage pull request is open unless the user assigned disjoint domains.
- Do not change production behavior or immutable migrations. Test files, fixtures, helpers, configuration, coverage tooling, and test-only infrastructure are in scope.
- Derive expectations from accepted contracts and observable behavior. Never copy the current implementation into assertions.
- Treat every new failure as a candidate finding. Do not fix an existing product bug in this wave.
- Always use Linear for confirmed bugs. File them as Bug, **Ready to Build**, with the owning milestone. Never use Todo.
- Use one repository coverage ledger as durable memory across runs and machines. Read and update it as described in [references/repository-coverage-ledger.md](references/repository-coverage-ledger.md). Do not create or update a Linear coverage tracking issue.
- Never run the complete integration or end-to-end suite during ordinary iteration. Read [references/execution-and-verification.md](references/execution-and-verification.md) before choosing test commands.

## One-pass workflow

1. Read repository instructions, test configuration, coverage setup, open coverage pull requests, the canonical repository coverage ledger, and live Linear conventions. Record the base SHA and current test health. Read the ledger before ranking targets.
2. Establish a comparable baseline. Rank domains by consequence, relative churn, coverage gap, oracle strength, test cost, and prior wave evidence. Read [references/target-selection.md](references/target-selection.md).
3. Select one coherent behavior matrix. Do not choose unrelated files or a target count.
4. Write the smallest faithful tests. Add a boundary or adversarial case per behavior class. Avoid incidental snapshots and mocks of the unit under test.
5. Prove sensitivity per behavior class with existing mutation tooling or a temporary behavioral perturbation. Confirm the intended failure, restore the change, and inspect the diff. Never add a mutation dependency unattended.
6. For a possible existing bug, pause that finding and follow [references/bug-validation-and-linear.md](references/bug-validation-and-linear.md). Continue independent matrix work when safe.
7. Run tiered gates, collect comparable coverage, and prepare impact, duration, finding, and next-target evidence.
8. Fetch again. Merge advanced `origin/main`, resolve only in-scope conflicts, and rerun affected gates.
9. After final resynchronization and verification, write a draft repository-ledger entry. Commit and push the tests plus draft entry, then open one pull request against `main`. Finalize the entry with the pull-request URL and terminal outcome. Commit, push, and read back the finalized entry before reporting completion. Do not merge the pull request.

## Loop and stop contract

Stop with one of these explicit outcomes:

- `READY_FOR_REVIEW`: one pull request is open with passing required gates and a finalized repository entry.
- `NO_HIGH_VALUE_TARGET`: evidence shows no suitable matrix for this pass. Use a ledger-only pull request.
- `BLOCKED_BY_BASELINE`: existing health prevents trustworthy comparison or acceptance.
- `BLOCKED_BY_CONTRACT`: expected behavior or the owning Linear milestone cannot be established.
- `BLOCKED_BY_DEPENDENCY`: required preview, service, credential, or tool is unavailable.
- `OPEN_COVERAGE_PR`: a prior wave must land before another starts. Perform no write.

For an investigated blocked outcome, use a ledger-only pull request. `OPEN_COVERAGE_PR` is the only terminal outcome that performs no ledger write.

Use the final-report contract in the execution reference. Counts without a terminal summary or exit code are not proof.
