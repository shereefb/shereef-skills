#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
checker="$repo_root/scripts/check-for-updates.sh"

if [[ ! -f "$checker" ]]; then
  printf 'FAIL: scripts/check-for-updates.sh is missing\n' >&2
  exit 1
fi

fixture_root="$(mktemp -d "${TMPDIR:-/tmp}/shereef-skills-updates.XXXXXX")"
trap 'rm -rf "$fixture_root"' EXIT

fake_bin="$fixture_root/bin"
mkdir -p "$fake_bin"

printf '%s\n' \
  '#!/usr/bin/env bash' \
  'if [[ "${FAKE_CURL_STATUS:-0}" -ne 0 ]]; then' \
  '  printf "fixture curl failure\n" >&2' \
  '  exit "$FAKE_CURL_STATUS"' \
  'fi' \
  'exec /bin/cat "$FAKE_CURL_RESPONSE"' \
  > "$fake_bin/curl"
chmod +x "$fake_bin/curl"

printf '%s\n' \
  '#!/usr/bin/env bash' \
  'printf "%s\n" "$*" >> "$NOTIFY_LOG"' \
  > "$fake_bin/osascript"
chmod +x "$fake_bin/osascript"

lock_file="$fixture_root/skill-lock.json"
api_response="$fixture_root/api-response.json"
notify_log="$fixture_root/notifications.log"
output_file="$fixture_root/output.log"

write_lock() {
  local source="${1:-shereefb/shereef-skills}"
  local hash="${2:-installed-hash}"

  printf '%s\n' \
    '{' \
    '  "skills": {' \
    '    "increase-test-coverage": {' \
    "      \"source\": \"$source\"," \
    '      "skillPath": "skills/increase-test-coverage/SKILL.md",' \
    "      \"skillFolderHash\": \"$hash\"" \
    '    }' \
    '  }' \
    '}' \
    > "$lock_file"
}

write_api_response() {
  local hash="${1:-installed-hash}"

  printf '%s\n' \
    '{' \
    '  "tree": [' \
    '    {' \
    '      "path": "skills/increase-test-coverage",' \
    '      "mode": "040000",' \
    '      "type": "tree",' \
    "      \"sha\": \"$hash\"" \
    '    }' \
    '  ]' \
    '}' \
    > "$api_response"
}

run_checker() {
  local status
  set +e
  PATH="$fake_bin:$PATH" \
    SHEREEF_SKILLS_LOCK_FILE="$lock_file" \
    SHEREEF_SKILLS_API_URL='https://example.invalid/tree' \
    FAKE_CURL_RESPONSE="$api_response" \
    NOTIFY_LOG="$notify_log" \
    bash "$checker" "$@" > "$output_file" 2>&1
  status=$?
  set -e
  return "$status"
}

assert_contains() {
  local file="$1"
  local expected="$2"

  if ! grep -Fq "$expected" "$file"; then
    printf 'FAIL: expected %s in %s\n' "$expected" "$file" >&2
    sed -n '1,120p' "$file" >&2
    exit 1
  fi
}

write_lock
write_api_response
if ! run_checker; then
  printf 'FAIL: matching hashes should exit 0\n' >&2
  sed -n '1,120p' "$output_file" >&2
  exit 1
fi
assert_contains "$output_file" 'increase-test-coverage is up to date.'

write_api_response 'upstream-hash'
if run_checker; then
  printf 'FAIL: a changed hash should not exit 0\n' >&2
  exit 1
else
  status=$?
fi
if [[ $status -ne 10 ]]; then
  printf 'FAIL: a changed hash should exit 10, got %s\n' "$status" >&2
  sed -n '1,120p' "$output_file" >&2
  exit 1
fi
assert_contains "$output_file" 'Update available for increase-test-coverage.'
assert_contains "$output_file" 'npx skills@latest update --global increase-test-coverage'
if [[ -e "$notify_log" ]]; then
  printf 'FAIL: a manual check should not send a notification\n' >&2
  exit 1
fi

if run_checker --notify; then
  printf 'FAIL: a notified update should still exit 10\n' >&2
  exit 1
else
  status=$?
fi
if [[ $status -ne 10 ]]; then
  printf 'FAIL: a notified update should exit 10, got %s\n' "$status" >&2
  exit 1
fi
assert_contains "$notify_log" 'Shereef Skills update available'
assert_contains "$notify_log" 'increase-test-coverage'

printf '%s\n' '{"skills": {}}' > "$lock_file"
if run_checker; then
  printf 'FAIL: a missing lock entry should fail\n' >&2
  exit 1
fi
assert_contains "$output_file" 'increase-test-coverage is not recorded'

write_lock 'another-owner/another-repo'
if run_checker; then
  printf 'FAIL: a foreign lock source should fail\n' >&2
  exit 1
fi
assert_contains "$output_file" 'unexpected source'

write_lock
if FAKE_CURL_STATUS=22 run_checker; then
  printf 'FAIL: a failed GitHub request should fail\n' >&2
  exit 1
fi
assert_contains "$output_file" 'could not fetch the GitHub tree'

printf '%s\n' '{"tree": []}' > "$api_response"
if run_checker; then
  printf 'FAIL: a missing upstream directory should fail\n' >&2
  exit 1
fi
assert_contains "$output_file" 'skill directory was not found'

printf 'Update checker tests passed: 7 cases\n'
