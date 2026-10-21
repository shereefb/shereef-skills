---
name: increase-test-coverage
description: Use when a repository needs a strategic test-coverage wave, especially when high-churn or high-consequence behavior is weakly tested and slow integration or end-to-end suites make broad iteration impractical.
---

# Increase test coverage

Run one bounded coverage wave per invocation. Improve confidence in important behavior, not the percentage alone. For a loop, accumulate verified waves on one dedicated branch and one rolling pull request. The next wave can start after publication and verification, without waiting for a merge or a change to `main`. A standalone invocation still ends after one wave.

## Required constraints

- Keep the main checkout untouched. A standalone wave starts in a fresh isolated worktree from fetched `origin/main`. A loop resumes its dedicated coverage worktree and branch. Read [references/rolling-branch.md](references/rolling-branch.md) before starting or resuming a loop.
- Reuse the loop's verified rolling pull request. Another coverage pull request stops admission unless the user assigned disjoint domains. Never append to a branch owned by another active writer.
- Do not change production behavior or immutable migrations. Test files, fixtures, helpers, configuration, coverage tooling, and test-only infrastructure are in scope.
- Derive expectations from accepted contracts and observable behavior. Never copy the current implementation into assertions.
- Treat every new failure as a candidate finding. Do not fix an existing product bug in this wave.
- Always use Linear for confirmed bugs. File them as Bug, **Ready to Build**, with the owning milestone. Never use Todo.
- Use one repository coverage ledger as durable memory across runs and machines. Read and update it as described in [references/repository-coverage-ledger.md](references/repository-coverage-ledger.md). Do not create or update a Linear coverage tracking issue.
- If repository-ledger storage or publication fails, preserve any available draft and evidence, report `BLOCKED_BY_DEPENDENCY` with the incomplete step, and do not claim `READY_FOR_REVIEW` or durable memory. Follow the failure rule in [references/repository-coverage-ledger.md](references/repository-coverage-ledger.md).
- Never run the complete integration or end-to-end suite during ordinary iteration. Read [references/execution-and-verification.md](references/execution-and-verification.md) before choosing test commands.

## One-pass workflow

1. Read repository instructions, test configuration, coverage setup, open coverage pull requests, the canonical repository coverage ledger, and live Linear conventions. Resolve standalone or rolling mode. Fetch and synchronize the selected branch before ranking. Record the wave-start base SHA and current test health. Read the ledger before ranking targets.
2. Establish a comparable baseline. Rank domains by consequence, relative churn, coverage gap, oracle strength, test cost, and prior wave evidence. Read [references/target-selection.md](references/target-selection.md).
3. Select one coherent behavior matrix. Do not choose unrelated files or a target count.
4. Write the smallest faithful tests. Add a boundary or adversarial case per behavior class. Avoid incidental snapshots and mocks of the unit under test.
5. Prove sensitivity per behavior class with existing mutation tooling or a temporary behavioral perturbation. Confirm the intended failure, restore the change, and inspect the diff. Never add a mutation dependency unattended.
6. For a possible existing bug, pause that finding and follow [references/bug-validation-and-linear.md](references/bug-validation-and-linear.md). Continue independent matrix work when safe.
7. Run tiered gates, collect comparable coverage, and prepare impact, duration, finding, and next-target evidence.
8. Fetch again. Merge advanced `origin/main`, resolve only in-scope conflicts, and rerun affected gates.
9. After final resynchronization and verification, write a draft repository-ledger entry. Commit and push the tests plus draft entry, then open or update the selected pull request against `main`. Finalize the entry with the pull-request URL and terminal outcome. Commit, push, and read back the finalized entry before reporting completion. In rolling mode, preserve separate commits and evidence for each wave and update the PR description to cover the accumulated changes. Do not merge the pull request.

## Loop and stop contract

Stop with one of these explicit outcomes:

- `READY_FOR_REVIEW`: the wave is published on the selected pull request with passing required gates and a finalized repository entry. In rolling mode this admits the next bounded wave on the same branch, even when the PR remains open and `main` is unchanged.
- `NO_HIGH_VALUE_TARGET`: evidence shows no suitable matrix for this pass. Publish a ledger-only result, reusing the rolling PR when present. End the loop until new evidence changes selection.
- `BLOCKED_BY_BASELINE`: existing health prevents trustworthy comparison or acceptance.
- `BLOCKED_BY_CONTRACT`: expected behavior or the owning Linear milestone cannot be established.
- `BLOCKED_BY_DEPENDENCY`: required preview, service, credential, or tool is unavailable.
- `BRANCH_CLOSED`: the selected rolling PR closed without merging. Preserve its branch and evidence, report the unlanded work, and perform no write.
- `OPEN_COVERAGE_PR`: an unrelated coverage PR occupies the lane, or ownership of a proposed rolling branch is unresolved. Perform no write. The selected rolling PR is not this blocker.

For an investigated blocked outcome, publish a ledger-only result. Reuse the rolling PR and retain its prior verified waves; do not publish unfinished tests as a completed wave. Except when ledger storage is unavailable, `OPEN_COVERAGE_PR` and `BRANCH_CLOSED` perform no ledger write.

Use the final-report contract in the execution reference. Counts without a terminal summary or exit code are not proof.
