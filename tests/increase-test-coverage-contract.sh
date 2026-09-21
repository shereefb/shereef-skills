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
expect_contains "$repository_ledger" 'For `NO_HIGH_VALUE_TARGET` or an investigated blocked outcome, use the same sequence with a ledger-only pull request.'
expect_contains "$repository_ledger" '`OPEN_COVERAGE_PR` is a preflight admission stop. It performs no write and opens no new pull request.'
expect_contains_all "$bug_reference" 'Ready to Build' 'milestone'
expect_contains "$skill_file" 'If repository-ledger storage or publication fails, preserve any available draft and evidence, report `BLOCKED_BY_DEPENDENCY` with the incomplete step, and do not claim `READY_FOR_REVIEW` or durable memory.'
expect_contains "$repository_ledger" 'If the ledger directory is unwritable, or commit, push, pull-request creation, finalization, or readback fails, preserve any available draft and evidence in a temporary file or the current branch.'
expect_contains "$repository_ledger" 'Report `BLOCKED_BY_DEPENDENCY` with the exact incomplete step and any existing branch or pull request. Do not claim `READY_FOR_REVIEW` or durable memory until the finalized entry is pushed and read back.'
expect_contains "$repository_ledger" 'If storage itself is unavailable, allow no ledger write. If a pull request already exists, resume and finalize that record instead of opening a second pull request.'
expect_no_stale_linear_ledger "$target_selection"
expect_no_stale_linear_ledger "$execution_verification"

printf 'Coverage ledger contract passed: 15 checks\n'
