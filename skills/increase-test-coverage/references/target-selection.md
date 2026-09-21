# Target selection

Choose one domain where added tests reduce meaningful risk. Coverage identifies missing execution; it does not prove test quality.

## Evidence to collect

- Recent relative churn from version control. Use a representative window, normally 60 to 120 days, and distinguish repeated edits from a single bulk move.
- Current line and branch coverage when the repository can produce comparable data.
- Defect history and open Linear bugs.
- Domain consequence, including authorization, money, destructive commands, data integrity, external side effects, and critical workflows.
- Existing unit, integration, and end-to-end tests.
- Whether the behavior has a strong oracle in an accepted product specification, API contract, schema invariant, migration, security rule, or public interface.
- Setup cost and the narrowest test layer that can prove the behavior.
- Prior wave outcomes from the repository's Linear coverage ledger: attempted and deferred matrices, coverage gain, bug yield, ruled-out findings, runtimes, flakes, and the last recommendation.

Do not rank generated code, vendored code, obsolete paths, or low-use presentation wrappers ahead of active domain behavior merely because their percentage is low.

## Ranking model

Use the evidence as a decision aid, not a mechanical formula:

| Factor | Prefer |
| --- | --- |
| Consequence | Security, money, data integrity, irreversible actions, critical workflow continuity |
| Churn | Repeated recent behavioral edits relative to the file or domain's size |
| Coverage gap | Missing branches and negative paths, not only uncovered lines |
| Oracle strength | A clear independent statement of expected behavior |
| Test leverage | Several related behaviors can be covered through one stable boundary |
| Cost | Fast deterministic tests with isolated setup |

Reject candidates whose only oracle is the implementation. If the contract is ambiguous, record `BLOCKED_BY_CONTRACT` for that candidate and choose another domain.

## Learn from prior waves

Use the Linear ledger as evidence, not as an instruction to repeat its last recommendation blindly.

- Prefer an untested high-risk matrix over repeating a recent low-yield slice.
- Revisit a prior domain when it has meaningful new churn, an incomplete matrix, a newly confirmed bug family, or a stronger oracle.
- Treat repeated setup failures, long durations, and flakes as selection cost until evidence shows they were resolved.
- Carry forward deferred matrices and ruled-out bug patterns so another machine does not repeat the same investigation without new evidence.
- Explain in the next ledger entry how prior outcomes affected the selected slice.

Git history remains the source for current code churn. The ledger records what coverage waves learned from that codebase; it is not a substitute for fresh repository and Linear evidence.

## Behavior matrix

Write the matrix before tests. Include:

- actor or caller;
- initial state;
- action or input class;
- expected result;
- persisted change or emitted event;
- prohibited side effects;
- boundary and negative cases;
- authoritative source for the expectation;
- faithful test layer.

The matrix is the wave boundary. A large wave covers one coherent domain well. It does not collect unrelated easy tests.

## Test-layer rule

Use the smallest layer that owns the truth:

- **Unit or component:** pure decisions, parsing, reducers, hooks, state machines, validation, and error presentation.
- **Integration:** SQL, row-level security, triggers, transactions, concurrency, service contracts, command boundaries, and real authentication decisions.
- **End to end:** routing, hydration, focus and keyboard behavior, browser storage, navigation persistence, or a critical journey that smaller tests cannot prove.

Do not replace an integration invariant with mocks or a browser invariant with component stubs merely to make the run faster.

## Expected-behavior rules

- Assert public inputs, outputs, persisted effects, emitted events, and absent side effects.
- Use current code to locate the boundary, not to define the answer.
- Treat nearby tests as supporting evidence, not as the sole contract.
- Avoid copying conditionals, private call order, or internal data structures into the test.
- Prefer explicit assertions over broad snapshots.
- Include a case that would fail under the most plausible wrong implementation.

## Impact history

Record confirmed mappings between production paths, unit tests, integration tests, end-to-end tests, required services, and observed durations in the Linear ledger. Add only mappings confirmed by successful runs. Do not claim that an inferred mapping is complete.

Update a repository-owned impact map only when that artifact already exists or repository instructions require it. Do not create one merely to give this skill memory.
