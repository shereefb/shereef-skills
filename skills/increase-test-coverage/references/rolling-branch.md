# Rolling coverage branch

Use this mode when the user requests a coverage loop. Each invocation covers one coherent matrix, then publishes its evidence. Merging belongs to the repository's delivery workflow and is not a prerequisite for another wave.

## Start or resume

Fetch origin and inspect the open coverage PRs, their head branches, current worktrees and repository ledger. Use one dedicated branch, such as `codex/coverage-loop`, in an isolated worktree with one writer. Record its branch, worktree, rolling PR URL and latest published wave in the ledger. Start it from fetched origin/main when no rolling branch exists.

An existing coverage PR produced by this loop, or explicitly assigned by the user, can become the rolling PR. Verify its repository, base, head, complete diff, ledger and current gates before adopting it. Keep its existing branch and history. A different active owner or unexplained local changes stop admission. Preserve those changes and resolve ownership before writing.

At the start of every wave, inspect the rolling PR's live state. If it remains open, resume its exact branch and fetch its remote head. Fast-forward remote additions only after verifying ownership and their scope. Reconcile divergence without force-pushing or overwriting another writer. If the PR merged, start a new branch from fetched main and open a new rolling PR after the next verified wave. If it closed without merging, report BRANCH_CLOSED and stop without writing or reopening. Report the unpublished-to-main work rather than silently reopening or discarding it.

## Wave boundary

Merge advanced origin/main into the branch before selecting the next matrix. Resolve only in-scope conflicts. A conflict requiring a production change stops that wave. Run gates affected by main's changes, including tests from earlier waves. Confirm the cumulative diff against main contains only permitted coverage work.

Use this synchronized branch head as the wave's `base_sha`. Measure before and after on that same tree, with all earlier coverage waves present. Record the synchronized main SHA separately in the ledger body. A main move during the wave requires resynchronization and the affected acceptance gates before publication. If it changes measurement inputs, repeat the before/after comparison on the synchronized tree. Temporarily reverse the current wave's owned test and support changes for that baseline, including edits to existing files. Preserve main and earlier waves, use the same measurement configuration for both runs, then restore the current wave exactly. Keep coverage denominators and test-scope changes explicit.

Read both landed ledger entries and the entries already on the rolling branch before ranking. Avoid repeating completed matrices. Select a new high-value matrix using current contracts, churn and gap evidence. Neither an unchanged main nor an open rolling PR is an admission blocker.

Keep each wave's tests and ledger in its own commits. Do not amend, squash or force-push previous waves. Finalized entries from previous waves remain historical evidence for their stated trees. If later main changes invalidate a test, explain the contract change and record its repair and verification in the current wave instead of rewriting an old result.

Run the existing test ladder and required gates for each wave. A growing branch also requires checks affected by interactions with earlier waves. Local acceptance and publication must complete before the next wave starts. If a hosted check is required, verify it on the finalized published head. Optional provider previews do not become required solely because they exist; report their actual status separately. Do not disable checks to keep the loop moving.

## Publication and continuation

Push the verified wave, add and finalize its new ledger entry, and read it back from the remote branch. Readback alone does not complete the wave. Wait for every required check on the exact finalized published head before reporting READY_FOR_REVIEW or admitting the next wave. Use the existing rolling PR URL for every wave on that branch. Create a PR only when the selected branch has none. Update its description with the accumulated domains, per-wave evidence and the validation scope of the latest head. Do not describe a rolling PR as fully verified using a result from an earlier tree.

After READY_FOR_REVIEW, the outer loop starts the next bounded wave from this branch. No merge or main-change wait is required. Stop on the user's stop request, NO_HIGH_VALUE_TARGET, a substantiated baseline or contract blocker, unresolved ownership, or a required unavailable dependency. For a pending required check, observe the current run and retry without launching a duplicate run. A transient wait is not permission to skip verification.

When the user asks to wrap up, finish only the active wave and leave the rolling PR for review. Its separate wave commits and ledger records let reviewers inspect individual matrices. Hand landing to the repository's merge workflow; the coverage loop never merges the PR or writes main.
