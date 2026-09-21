# Linear coverage ledger

Use one persistent Linear issue per repository as the skill's cross-run memory. This is an evidence ledger, not machine learning: each run reads structured prior outcomes, combines them with fresh Git and coverage evidence, and records what the run learned.

## Find or create the ledger

1. Resolve the canonical repository identity from its Git remote.
2. Search Linear for an issue titled `Test coverage ledger — <owner>/<repository>` and confirm the repository URL in its description.
3. Reuse one exact match. If duplicates exist, stop and resolve the canonical ledger before writing.
4. If none exists, identify the repository's owning Linear team from live project or issue conventions and create one non-Bug tracking issue. Do not label it Bug or place it in Ready to Build merely because product bugs use that workflow. Do not guess a team, project, milestone, or status.

The description identifies the repository, explains the append-only comment format, and maintains:

- a concise current rollup of covered domains, ruled-out patterns, known expensive boundaries, unresolved blockers, deferred matrices, and the current next recommendation;
- a compact run index keyed by UTC timestamp, base SHA, terminal outcome, domain, and comment link.

Keep immutable per-run evidence in comments.

## Read before selection

Read the description and exhaust pagination for all run comments before ranking targets. If the available Linear client cannot retrieve complete comment history, require the description's run index and current rollup to account for every prior entry; otherwise return `BLOCKED_BY_DEPENDENCY` rather than treating a partial history as complete. Extract:

- attempted, completed, blocked, and deferred behavior matrices;
- repository and selected-domain coverage changes;
- confirmed bugs, ruled-out candidates, and discovered bug families;
- focused, integration, and end-to-end durations plus flakes or retry-only results;
- confirmed test-impact mappings and unavailable dependencies;
- the prior recommendation and the evidence behind it.

Fresh evidence wins when repository state, Linear contracts, or test health changed. State how the ledger altered the new ranking; if it did not, say why.

## Append every terminal outcome

After final resynchronization, verification, commit, and pull-request creation, but before reporting a terminal state, append one comment with:

- UTC timestamp, repository, base SHA, head SHA when present, branch, and pull-request link;
- terminal outcome;
- selected domain and behavior matrix, including authoritative contracts;
- why it outranked alternatives and how prior history affected the choice;
- comparable before-and-after line and branch coverage for the repository and selected domain;
- tests added, focused gates, exit codes, durations, and sensitivity evidence;
- integration or end-to-end files run, their durations, and full suites deliberately not run;
- candidate findings with `confirmed`, `ruled out`, `not proven`, or the independent-investigator classification;
- confirmed bug links, Ready to Build status, and owning milestones;
- confirmed impact mappings, blockers, deferred matrices, and the next recommendation.

For blocked or no-target outcomes, record the investigation and the evidence needed to unblock it. A wave with no confirmed bug still writes a ledger entry.

Update the description rollup and run index after appending the comment, then read the issue back and verify the repository identity, comment, final SHA and pull-request links, index entry, and rollup. Check that the ledger is readable and writable before beginning test edits. If the final write fails, do not claim durable learning or `READY_FOR_REVIEW`; report `BLOCKED_BY_DEPENDENCY` with the already-created pull request. If Linear is unavailable at the initial check, stop before opening a pull request unless the user explicitly chooses a run without persistent memory.

## Storage boundary

- Linear holds cross-run decisions, compact measurements, classifications, and links.
- Git and merged pull requests remain the source for code churn and exact test changes.
- CI artifacts or temporary files hold raw logs; do not paste large logs into Linear or commit them for this skill.
- Product bugs remain separate Bug issues in Ready to Build with the owning milestone and link back to the ledger entry.
