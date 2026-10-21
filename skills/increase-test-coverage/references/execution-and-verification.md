# Execution and verification

## Test ladder

Run the narrowest useful command first:

1. Exact new or changed test files while authoring.
2. The selected domain's sibling matrix.
3. The complete unit suite once before handoff when its measured duration is reasonable.
4. Selected integration files once when the behavior depends on a real database or service boundary.
5. Selected end-to-end files once when the behavior depends on a real browser boundary.

Do not run the complete integration or end-to-end suite as a routine coverage-wave gate. Put those suites in a separate main-health, scheduled, merge, or release lane. Do not report an unrun suite as passing.

Use framework-native selection where available, such as exact file paths, title filters, projects, changed-file coverage, or test groups. Use last-failed filters only to diagnose. Acceptance must rerun the intended selected set from a clean state.

## Slow-suite optimization

Record per-file and setup durations whenever integration or end-to-end tests run. Use that evidence to improve later selection.

- Reuse one exact build within the same end-to-end run when supported.
- Separate read-only tests from tests that mutate shared state.
- Create a small critical-journey end-to-end project when the repository has clear high-value flows.
- Do not enable file parallelism, more workers, or sharding against shared mutable fixtures.
- Increase concurrency only after run-unique companies, users, schemas, ports, or equivalent resources isolate workers.
- Shard by measured duration when the runner supports it. File-count balance alone can hide a slow shard.

Test-only performance changes may join the wave when they preserve semantics, remain reviewable, and directly enable the selected matrix. Record larger optimization work as a separate recommendation.

## Coverage comparison

Use the same command, configuration, environment, and scope before and after. Report lines and branches when available. Also report the selected domain's change, because a high-value integration test may barely move the repository percentage.

A successful wave requires:

- no unexplained coverage regression;
- completed behavior-matrix rows;
- fresh passing focused tests;
- the full unit gate once when feasible;
- selected integration or end-to-end gates when their layer owns the truth;
- sensitivity evidence for each behavior class;
- explicit exit codes and terminal summaries.

Do not weaken exclusions, omit difficult files, or add low-value assertions to manufacture a percentage increase.

## Baseline failures

Reproduce an existing failure before attributing it to the wave. If instrumentation changes timing, rerun the same test without instrumentation before classifying the failure. Do not treat retry-only success as acceptance evidence.

If baseline health prevents trustworthy work, record `BLOCKED_BY_BASELINE`. File a Linear bug only after the independent validation gate in the bug reference.

## Evidence record

Write the durable run record to the repository's canonical coverage-ledger entry. Put the review-facing subset in the pull-request description.

The repository entry contains:

1. Required frontmatter: `version`, repository, start and finish times, base SHA, terminal outcome, domain, and pull request. Git history identifies the commits that added and finalized the entry.
2. Why this domain outranked alternatives.
3. Expected-behavior sources and completed matrix.
4. Files changed, limited to tests and test support.
5. Every command, exit code, duration, and terminal summary.
6. Comparable before-and-after line and branch coverage.
7. Sensitivity checks and their observed failures.
8. Confirmed Linear bugs with status and milestone.
9. Unconfirmed candidates and why they were not filed.
10. Full suites deliberately not run and the lane that owns them.
11. Confirmed impact mappings and measured durations.
12. The next recommended domain matrix and how prior ledger evidence influenced this wave.
13. For a rolling loop, the branch, synchronized main SHA, prior published wave, per-wave commit boundary and cumulative validation scope.

Keep raw command and test logs in temporary workspace files or CI artifacts and link them when a durable URL exists. Do not commit raw logs merely to preserve the skill's history. Terminal summaries, exit codes, durations, and relevant failure excerpts belong in the ledger entry.

## Final resync

Fetch `origin` immediately before handoff. If `origin/main` advanced, merge it into the coverage branch. Never write directly to `main`. Rerun tests affected by the merge, then rerun the acceptance gates needed for current evidence. Follow the repository-ledger write sequence before reporting completion. Do not merge the pull request.

In rolling mode, handoff is publication of this wave on the existing branch and PR. Verify the cumulative coverage diff and gates affected by interactions with earlier waves. READY_FOR_REVIEW allows the next wave without waiting for a merge or new main commit. Read [rolling-branch.md](rolling-branch.md) for branch ownership, lifecycle and comparison rules.

## Final report

Report the terminal outcome, branch and PR URL, finalized published head, required gate results and their verified scope, comparable coverage, any blocker, and whether the loop continues. Distinguish earlier-tree results from current-head verification. In rolling mode, identify the completed wave and cumulative PR scope. Report READY_FOR_REVIEW only after remote ledger readback and all required checks pass on the finalized head.
