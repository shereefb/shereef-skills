# Repository coverage ledger design

Date: 2026-09-20
Status: Approved in conversation

## Goal

Give `increase-test-coverage` durable memory that travels with the repository. Each run must learn from earlier coverage waves without using Linear as the history store or creating a shared file that causes avoidable merge conflicts.

Linear remains the system of record for confirmed product bugs. The repository ledger records coverage-wave decisions and results.

## Storage model

The default ledger is an append-only directory:

```text
docs/testing/coverage-ledger/
  2026-09-20T214500Z-auth-routing-a1b2c3d4.md
```

Each terminal run adds one Markdown file. Existing entries are immutable after their pull request merges. A repository may override the path through its own instructions, but the skill must use one canonical ledger location per repository.

A directory of entries is preferred over one Markdown or JSON Lines file because independent branches can add records without editing the same file. Git supplies ordering, authorship, review, and change history.

## Entry identity and metadata

Use a UTC filename with the selected domain and the first eight characters of the base SHA:

```text
YYYY-MM-DDTHHMMSSZ-<domain-slug>-<base-sha8>.md
```

The file starts with YAML frontmatter:

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

Recorded outcomes use the skill's terminal outcomes. `pull_request` is required because every recorded run, including blocked and no-target investigations, opens at most one pull request containing its ledger entry.

`OPEN_COVERAGE_PR` is a preflight admission stop, not a completed investigation. It does not create another ledger entry or pull request because the existing open pull request already blocks the lane.

The entry does not store its own final commit SHA. A file cannot contain the SHA of the commit that contains that file without creating a circular value. Git history identifies the commits that added and finalized the entry.

## Entry body

Each entry records:

1. The selected behavior matrix and its authoritative contracts.
2. Why the domain outranked alternatives, including the prior ledger evidence that affected selection.
3. Comparable repository and domain coverage before and after the wave.
4. Tests added, commands, exit codes, durations, and sensitivity evidence.
5. Integration or end-to-end files run and the full suites deliberately omitted.
6. Candidate findings classified as confirmed, ruled out, not proven, or by the independent investigator's result.
7. Confirmed Linear bugs with Ready to Build status and owning milestone.
8. Confirmed test-impact mappings, blockers, deferred matrices, and the next recommendation.

Raw logs do not belong in the ledger. Keep them in temporary files or CI artifacts and link durable artifacts when available.

## Reading and target selection

Before selecting a matrix, the skill locates the repository's canonical ledger directory. It inventories the YAML frontmatter for every entry, then reads:

- the most recent completed and blocked waves;
- every prior entry for candidate domains;
- entries that mention related bug families, dependencies, or slow test boundaries.

The skill combines this history with fresh Git churn, current coverage, live Linear bugs, and current test health. It must explain how prior evidence changed the ranking or state that it did not.

The ledger is evidence, not an instruction to repeat the last recommendation. A previous domain becomes eligible again when new churn, an incomplete matrix, a related confirmed bug, or a stronger contract changes the risk.

## Write sequence

The skill checks before test edits that it can create a ledger entry in the coverage worktree. It keeps the draft uncommitted while it runs tests.

For a successful coverage wave:

1. Complete the selected tests and final resynchronization.
2. Write the draft entry with all evidence except the pull-request URL.
3. Commit and push the test changes and draft entry.
4. Open one pull request.
5. Add the pull-request URL and final terminal outcome to the entry.
6. Commit and push the finalized entry.
7. Read the file from the branch and verify its metadata and required evidence before reporting completion.

For `NO_HIGH_VALUE_TARGET` or a blocked outcome reached after investigation, the skill follows the same sequence with a ledger-only pull request. The entry documents what it inspected, why it stopped, and what evidence could change the result. This prevents another run from repeating the investigation without new information.

An open coverage or ledger-only pull request still triggers the existing one-open-PR stop rule unless the user assigned disjoint domains.

## Linear boundary

The repository ledger replaces the Linear coverage ledger completely. The skill must not create or update a Linear tracking issue for coverage history.

Confirmed defects remain separate Linear Bug issues. Each bug is filed in Ready to Build with the owning milestone, contains its reproduction evidence, and links to the coverage pull request when available.

## Skill changes

Implementation will:

- replace `references/linear-coverage-ledger.md` with `references/repository-coverage-ledger.md`;
- update the entrypoint, target-selection, execution, and bug-validation references to use the repository ledger;
- remove every instruction that treats Linear as coverage-wave memory;
- preserve Linear bug filing rules;
- update validators or behavioral checks needed to prevent both ledger systems from appearing at once;
- update the installed Claude and Codex copies after the repository change passes validation and lands on the public repository.

## Verification

Behavioral validation must show that a fresh agent:

- reads prior repository entries before choosing a slice;
- does not create a Linear coverage tracker;
- adds one new ledger entry without editing earlier entries;
- creates a ledger-only pull request for blocked and no-target outcomes;
- keeps raw logs out of the repository;
- continues filing confirmed bugs in Linear with Ready to Build status and the correct milestone.

Repository validation must pass for the canonical skill, Claude plugin manifest, Codex metadata, public installer discovery, and both installed copies.
