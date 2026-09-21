#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
skill_root="$repo_root/skills/increase-test-coverage"
skill_file="$skill_root/SKILL.md"
repository_ledger="$skill_root/references/repository-coverage-ledger.md"
linear_ledger="$skill_root/references/linear-coverage-ledger.md"
bug_reference="$skill_root/references/bug-validation-and-linear.md"

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

expect_file "$repository_ledger"
expect_absent "$linear_ledger"
expect_contains "$skill_file" 'references/repository-coverage-ledger.md'
expect_not_contains "$skill_file" 'Linear coverage ledger'
expect_contains "$repository_ledger" 'docs/testing/coverage-ledger/'
expect_contains "$repository_ledger" 'NO_HIGH_VALUE_TARGET'
expect_contains "$repository_ledger" 'OPEN_COVERAGE_PR'
expect_contains "$repository_ledger" 'Linear coverage tracking issue'
expect_contains_all "$bug_reference" 'Ready to Build' 'milestone'

printf 'Coverage ledger contract passed: 9 checks\n'
