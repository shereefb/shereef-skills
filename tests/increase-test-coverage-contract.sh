#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
skill_root="$repo_root/skills/increase-test-coverage"
skill_file="$skill_root/SKILL.md"
repository_ledger="$skill_root/references/repository-coverage-ledger.md"
linear_ledger="$skill_root/references/linear-coverage-ledger.md"
bug_reference="$skill_root/references/bug-validation-and-linear.md"
target_selection="$skill_root/references/target-selection.md"
execution_verification="$skill_root/references/execution-and-verification.md"
rolling_branch="$skill_root/references/rolling-branch.md"

fail() {
  printf 'FAIL: %s; expected %s\n' "$1" "$2" >&2
  exit 1
}

expect_file() {
  [[ -f "$1" ]] || fail "$1" 'file to exist'
}

expect_absent() {
  [[ ! -e "$1" ]] || fail "$1" 'path to be absent'
}

expect_contains() {
  grep -Fq -- "$2" "$1" || fail "$1" "text: $2"
}

expect_not_contains() {
  ! grep -Fq -- "$2" "$1" || fail "$1" "text to be absent: $2"
}

expect_contains_all() {
  expect_contains "$1" "$2"
  expect_contains "$1" "$3"
}

expect_no_stale_linear_ledger() {
  expect_not_contains "$1" 'Linear ledger'
  expect_not_contains "$1" 'Linear coverage ledger'
}

expect_file "$repository_ledger"
expect_absent "$linear_ledger"
expect_contains "$skill_file" 'references/repository-coverage-ledger.md'
expect_not_contains "$skill_file" 'Linear coverage ledger'
expect_contains "$repository_ledger" 'docs/testing/coverage-ledger/'
expect_contains "$repository_ledger" 'Do not create or update a Linear coverage tracking issue.'
expect_contains "$repository_ledger" 'For `NO_HIGH_VALUE_TARGET` or an investigated blocked outcome, use the same sequence with a ledger-only result.'
expect_contains "$repository_ledger" '`OPEN_COVERAGE_PR` is a preflight admission stop for an unrelated coverage PR or unresolved branch ownership.'
expect_contains "$repository_ledger" 'It performs no write and opens no new pull request.'
expect_contains_all "$bug_reference" 'Ready to Build' 'milestone'
expect_contains "$skill_file" 'If repository-ledger storage or publication fails, preserve any available draft and evidence, report `BLOCKED_BY_DEPENDENCY` with the incomplete step, and do not claim `READY_FOR_REVIEW` or durable memory.'
expect_contains "$repository_ledger" 'If the ledger directory is unwritable, or commit, push, pull-request creation, finalization, or readback fails, preserve any available draft and evidence in a temporary file or the current branch.'
expect_contains "$repository_ledger" 'Report `BLOCKED_BY_DEPENDENCY` with the exact incomplete step and any existing branch or pull request. Do not claim `READY_FOR_REVIEW` or durable memory until the finalized entry is pushed and read back.'
expect_contains "$repository_ledger" 'If storage itself is unavailable, allow no ledger write. If a pull request already exists, resume and finalize that record instead of opening a second pull request.'
expect_no_stale_linear_ledger "$target_selection"
expect_no_stale_linear_ledger "$execution_verification"

expect_file "$rolling_branch"
expect_contains "$skill_file" 'references/rolling-branch.md'
expect_contains "$skill_file" 'The next wave can start after publication and verification, without waiting for a merge or a change to `main`.'
expect_contains "$rolling_branch" 'Use the existing rolling PR URL for every wave on that branch.'
expect_contains "$rolling_branch" 'A different active owner or unexplained local changes stop admission.'
expect_contains "$rolling_branch" 'If the PR merged, start a new branch from fetched main'
expect_contains "$rolling_branch" 'If it closed without merging, report BRANCH_CLOSED and stop without writing or reopening.'
expect_contains "$rolling_branch" "Use this synchronized branch head as the wave's \`base_sha\`."
expect_contains "$rolling_branch" 'If a hosted check is required, verify it on the finalized published head.'
expect_contains "$rolling_branch" 'Do not amend, squash or force-push previous waves.'
expect_contains "$rolling_branch" 'the coverage loop never merges the PR or writes main.'
expect_not_contains "$skill_file" 'a prior wave must land before another starts'

printf 'Coverage ledger and rolling branch contract passed\n'
