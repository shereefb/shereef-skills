#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
validator="$repo_root/scripts/validate.sh"

if [[ ! -f "$validator" ]]; then
  printf 'FAIL: validator is missing: %s\n' "$validator" >&2
  exit 1
fi

fixture_root="$(mktemp -d "${TMPDIR:-/tmp}/shereef-skills-validation.XXXXXX")"
trap 'rm -rf "$fixture_root"' EXIT

make_valid_repo() {
  local root="$1"
  mkdir -p "$root/skills/example-skill/references" "$root/skills/example-skill/agents" "$root/.claude-plugin"

  printf '%s\n' \
    '---' \
    'name: example-skill' \
    'description: Use when an example repository needs a validation fixture.' \
    '---' \
    '' \
    '# Example skill' \
    '' \
    'Read [the reference](references/example.md).' \
    > "$root/skills/example-skill/SKILL.md"

  printf '%s\n' '# Example reference' > "$root/skills/example-skill/references/example.md"

  printf '%s\n' \
    'interface:' \
    '  display_name: "Example Skill"' \
    '  short_description: "Validate an example skill repository"' \
    > "$root/skills/example-skill/agents/openai.yaml"

  printf '%s\n' \
    '{' \
    '  "name": "fixture-skills",' \
    '  "owner": { "name": "Fixture" },' \
    '  "plugins": [' \
    '    {' \
    '      "name": "fixture-skills",' \
    '      "description": "Validation fixture",' \
    '      "source": "./",' \
    '      "strict": false,' \
    '      "skills": ["./skills/example-skill"]' \
    '    }' \
    '  ]' \
    '}' \
    > "$root/.claude-plugin/marketplace.json"

  printf '%s\n' '# Fixture skills' > "$root/README.md"
}

expect_pass() {
  local name="$1"
  local root="$2"
  local output

  if ! output="$(bash "$validator" "$root" 2>&1)"; then
    printf 'FAIL: %s should pass\n%s\n' "$name" "$output" >&2
    exit 1
  fi

  if [[ "$output" != *'Validation passed: 1 skill(s)'* ]]; then
    printf 'FAIL: %s returned an unexpected summary\n%s\n' "$name" "$output" >&2
    exit 1
  fi
}

expect_fail() {
  local name="$1"
  local root="$2"
  local expected="$3"
  local output

  if output="$(bash "$validator" "$root" 2>&1)"; then
    printf 'FAIL: %s should fail\n%s\n' "$name" "$output" >&2
    exit 1
  fi

  if [[ "$output" != *"$expected"* ]]; then
    printf 'FAIL: %s did not report %s\n%s\n' "$name" "$expected" "$output" >&2
    exit 1
  fi
}

valid_root="$fixture_root/valid"
make_valid_repo "$valid_root"
expect_pass 'valid repository' "$valid_root"

name_root="$fixture_root/name-mismatch"
make_valid_repo "$name_root"
sed -i.bak 's/name: example-skill/name: different-name/' "$name_root/skills/example-skill/SKILL.md"
rm "$name_root/skills/example-skill/SKILL.md.bak"
expect_fail 'directory and name mismatch' "$name_root" 'does not match directory'

reference_root="$fixture_root/broken-reference"
make_valid_repo "$reference_root"
sed -i.bak 's/references\/example.md/references\/missing.md/' "$reference_root/skills/example-skill/SKILL.md"
rm "$reference_root/skills/example-skill/SKILL.md.bak"
expect_fail 'broken local reference' "$reference_root" 'broken local reference'

manifest_root="$fixture_root/unlisted-skill"
make_valid_repo "$manifest_root"
mkdir -p "$manifest_root/skills/second-skill"
printf '%s\n' \
  '---' \
  'name: second-skill' \
  'description: Use when a second fixture skill is needed.' \
  '---' \
  '' \
  '# Second skill' \
  > "$manifest_root/skills/second-skill/SKILL.md"
expect_fail 'skill missing from marketplace' "$manifest_root" 'is not listed in marketplace.json'

placeholder_root="$fixture_root/placeholder"
make_valid_repo "$placeholder_root"
printf '%s\n' '[TODO] Replace this text.' >> "$placeholder_root/README.md"
expect_fail 'published placeholder' "$placeholder_root" 'unfinished placeholder'

yaml_root="$fixture_root/invalid-yaml"
make_valid_repo "$yaml_root"
printf '%s\n' 'interface: [broken' > "$yaml_root/skills/example-skill/agents/openai.yaml"
expect_fail 'invalid Codex metadata' "$yaml_root" 'invalid YAML'

printf 'Validator tests passed: 6 cases\n'

bash "$repo_root/tests/update-prompts.sh"
