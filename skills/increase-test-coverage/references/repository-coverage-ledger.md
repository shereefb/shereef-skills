# Repository coverage ledger

## Canonical location

Use one canonical ledger directory for each repository. The default is `docs/testing/coverage-ledger/`. Repository instructions may name a different location. Resolve that location before selecting a target and check that the coverage worktree can add an entry there before editing tests.

The ledger is append-only. Each terminal coverage wave adds one Markdown entry. Do not create or update a Linear coverage tracking issue. Linear remains the system of record for confirmed product bugs.

## Entry identity and frontmatter

Name each entry `YYYY-MM-DDTHHMMSSZ-<domain-slug>-<base-sha8>.md`, using UTC, the selected domain slug, and the first eight characters of the base SHA.

Start every entry with this YAML frontmatter:

```yaml
---
version: 1
repository: owner/repository
started_at: 2026-09-20T21:45:00Z
finished_at: 2026-09-20T23:10:00Z
base_sha: a1b2c3d4e5f6...
outcome: READY_FOR_REVIEW
domain: auth-routing
pull_request: https://github.com/owner/repository/pull/123
---
```

Require all eight fields in the finalized entry. Do not record the entry's own final commit SHA. That SHA cannot be written into the file it identifies without changing the file and creating a circular value. Git history identifies the commits that added and finalized the entry.

The body records the selected behavior matrix and its authoritative contracts, the ranking and prior-ledger evidence, comparable repository and domain coverage before and after, tests and commands with exit codes, durations, and sensitivity evidence, integration or end-to-end files run, deliberately omitted full suites, and candidate findings classified as `confirmed`, `ruled out`, `not proven`, or by the independent investigator. Record confirmed Linear bugs with their `Ready to Build` status and owning milestones, confirmed impact mappings, blockers, deferred matrices, and the next recommendation.

## Read before selection

Before ranking targets, inventory the YAML frontmatter for every ledger entry. Then read the bodies for recent completed and blocked waves, every prior entry for candidate domains, and entries about related bug families, dependencies, or slow test boundaries.

Combine this history with fresh Git churn, current coverage, live Linear bugs, and current test health. Explain how prior evidence changed the ranking, or state why it did not. Ledger history is evidence, not an instruction to repeat the prior recommendation. Revisit a domain when new churn, an incomplete matrix, a related confirmed bug, or a stronger contract changes its risk.

## Write sequence

After completing the selected tests, final resynchronization, and verification, write an uncommitted draft entry with all available evidence. Commit and push the tests plus the draft entry. Open one pull request. Finalize the entry with the pull-request URL and terminal outcome, then commit, push, and read back the finalized entry from the branch. Verify its metadata and required evidence before reporting completion.

## Blocked and no-target outcomes

For `NO_HIGH_VALUE_TARGET` or an investigated blocked outcome, use the same sequence with a ledger-only pull request. Record what was inspected, why the wave stopped, and what evidence could change the result. This prevents another wave from repeating the investigation without new information.

`OPEN_COVERAGE_PR` is a preflight admission stop. It performs no write and opens no new pull request. The existing coverage or ledger-only pull request already occupies the lane, unless the user assigned disjoint domains.

## Storage boundary

Keep coverage-wave decisions and results in the repository ledger. Do not create a Linear coverage tracker or separate tracking issue. Do not change entries after their pull requests merge. Keep raw logs in temporary files or CI artifacts, and link durable artifacts when available instead of committing logs.

Keep confirmed defects in separate Linear Bug issues. File each as `Ready to Build` with its owning milestone, reproduction evidence, and a link to the coverage pull request when available.
