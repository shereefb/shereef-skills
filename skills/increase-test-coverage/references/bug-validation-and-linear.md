# Bug validation and Linear filing

An unexpected result is a candidate finding, not a bug. Try to disprove it before filing.

## Confirmation gate

1. State the expected behavior and cite its independent source. A nearby test alone is not enough.
2. Build the smallest machine-executable reproducer at the layer that owns the truth.
3. Reproduce against the exact current `origin/main` SHA from a clean state. Check fixtures, identities, clocks, caches, mocks, database state, and environment.
4. Add a negative control. Repeat deterministic failures. For races, collect controlled evidence rather than calling one failure proof.
5. Ask a fresh-context subagent using the highest-capability available model and high reasoning to investigate independently. Give it the contract source, reproduction patch, command, output, and base SHA. Tell it to falsify the finding and forbid product edits or external writes.
6. Require one classification: `CONFIRMED_PRODUCT_BUG`, `TEST_BUG`, `TEST_INFRA_BUG`, `ENVIRONMENTAL`, `CONTRACT_AMBIGUITY`, `EXPECTED_BEHAVIOR`, or `INCONCLUSIVE`.

If an independent subagent is unavailable, preserve the candidate in the receipt and do not file it as a bug.

## Reproducer policy

Every filed bug needs reproducible evidence. Prefer a machine-executable failing test, then an executable reproduction script. If faithful automation is impossible, the independent investigator must confirm that limitation before filing. The card must document the reason and attach exact manual steps with equivalent runtime evidence.

Do not commit a known-red product-bug test to the passing coverage pull request. Attach the minimal patch to Linear when supported. Otherwise include the complete small test or reproduction script in the card, with the exact command and failure output. The future bug-fix branch begins by applying this reproducer and observing it fail.

Do not skip the test, mark it expected-failing, weaken its assertion, or change the expectation to match broken behavior. Those actions normalize the defect.

## Pattern search

After confirmation, extract the violated invariant and likely mechanism. Search callers, sibling handlers, policies, migrations, commands, and equivalent workflows for the same semantic pattern. Similar syntax is only a lead.

Independently reproduce each occurrence and label it `confirmed`, `ruled out`, or `not proven`. Do not inflate the card with unverified matches.

- Use one Linear bug when confirmed occurrences share a root cause, owner, and milestone.
- Create linked bugs when ownership, milestone, or remediation differs.
- Require the eventual fix to cover every confirmed occurrence with a regression matrix.

The coverage wave identifies and documents the family. It does not fix production behavior.

## Linear contract

Always use Linear. Before creating a card, search for duplicates and read the live team workflow, labels, statuses, projects, and milestones.

For every confirmed defect:

- issue type or label: `Bug`;
- status: `Ready to Build`, never `Todo`;
- milestone: the milestone that owns the affected behavior;
- main-health or test-infrastructure milestone only when the defect belongs to repository health rather than the product domain;
- links to related bugs and the coverage pull request when available.

Do not guess the milestone. If live Linear evidence cannot resolve it, record `BLOCKED_BY_CONTRACT` and preserve the confirmed evidence without filing an incorrectly routed card.

The card must include:

- expected behavior and its source;
- observed behavior;
- exact repository SHA and environment;
- executable reproduction and command;
- expected and actual output;
- repeat count or race evidence;
- independent investigator classification and reasoning;
- confirmed adjacent occurrences and ruled-out lookalikes;
- acceptance criteria for the whole confirmed family;
- explicit note that the coverage wave did not fix the defect.

After creation, read the card back from Linear and verify its title, Bug classification, Ready to Build status, milestone, description, relations, and attachments.
