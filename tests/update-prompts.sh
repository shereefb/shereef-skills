#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
checker="$repo_root/scripts/check-for-updates.sh"
installer="$repo_root/scripts/install-update-prompt-macos.sh"
uninstaller="$repo_root/scripts/uninstall-update-prompt-macos.sh"

if [[ ! -f "$checker" ]]; then
  printf 'FAIL: scripts/check-for-updates.sh is missing\n' >&2
  exit 1
fi

if [[ ! -f "$installer" ]]; then
  printf 'FAIL: scripts/install-update-prompt-macos.sh is missing\n' >&2
  exit 1
fi

if [[ ! -f "$uninstaller" ]]; then
  printf 'FAIL: scripts/uninstall-update-prompt-macos.sh is missing\n' >&2
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

printf '%s\n' \
  '#!/usr/bin/env bash' \
  'printf "Darwin\n"' \
  > "$fake_bin/uname"
chmod +x "$fake_bin/uname"

printf '%s\n' \
  '#!/usr/bin/env bash' \
  'printf "%s\n" "$*" >> "$LAUNCHCTL_LOG"' \
  > "$fake_bin/launchctl"
chmod +x "$fake_bin/launchctl"

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

test_home="$fixture_root/home"
launchctl_log="$fixture_root/launchctl.log"
install_output="$fixture_root/install-output.log"
marker='Managed by shereef-skills update prompt'

reset_test_home() {
  rm -rf "$test_home"
  mkdir -p "$test_home"
  : > "$launchctl_log"
}

run_installer() {
  HOME="$test_home" \
    PATH="$fake_bin:$PATH" \
    LAUNCHCTL_LOG="$launchctl_log" \
    bash "$installer" > "$install_output" 2>&1
}

run_uninstaller() {
  HOME="$test_home" \
    PATH="$fake_bin:$PATH" \
    LAUNCHCTL_LOG="$launchctl_log" \
    bash "$uninstaller" > "$install_output" 2>&1
}

reset_test_home
if ! run_installer; then
  printf 'FAIL: installer should succeed in an empty home\n' >&2
  sed -n '1,160p' "$install_output" >&2
  exit 1
fi

installed_checker="$test_home/Library/Application Support/Shereef Skills/check-for-updates.sh"
installed_plist="$test_home/Library/LaunchAgents/com.shereef-skills.update-check.plist"
stdout_log="$test_home/Library/Logs/Shereef Skills/update-check.log"
stderr_log="$test_home/Library/Logs/Shereef Skills/update-check.error.log"

for installed_file in "$installed_checker" "$installed_plist"; do
  if [[ ! -f "$installed_file" ]]; then
    printf 'FAIL: installer did not create %s\n' "$installed_file" >&2
    exit 1
  fi
  assert_contains "$installed_file" "$marker"
done

assert_contains "$installed_plist" "$installed_checker"
assert_contains "$installed_plist" '<key>Weekday</key><integer>1</integer>'
assert_contains "$installed_plist" '<key>Hour</key><integer>10</integer>'
assert_contains "$installed_plist" '<string>--notify</string>'
assert_contains "$installed_plist" "$stdout_log"
assert_contains "$installed_plist" "$stderr_log"
assert_contains "$launchctl_log" "bootstrap gui/$(id -u) $installed_plist"

reset_test_home
mkdir -p "$(dirname "$installed_plist")"
printf 'foreign launch agent\n' > "$installed_plist"
if run_installer; then
  printf 'FAIL: installer should reject an unmarked plist\n' >&2
  exit 1
fi
if [[ "$(< "$installed_plist")" != 'foreign launch agent' ]]; then
  printf 'FAIL: installer changed an unmarked plist\n' >&2
  exit 1
fi
assert_contains "$install_output" 'refusing to replace unmarked file'

reset_test_home
run_installer
mkdir -p "$(dirname "$stdout_log")"
printf 'kept output\n' > "$stdout_log"
printf 'kept errors\n' > "$stderr_log"
: > "$launchctl_log"
if ! run_uninstaller; then
  printf 'FAIL: uninstaller should remove marked files\n' >&2
  sed -n '1,160p' "$install_output" >&2
  exit 1
fi
if [[ -e "$installed_checker" || -e "$installed_plist" ]]; then
  printf 'FAIL: uninstaller left a managed file behind\n' >&2
  exit 1
fi
if [[ ! -f "$stdout_log" || ! -f "$stderr_log" ]]; then
  printf 'FAIL: uninstaller removed retained logs\n' >&2
  exit 1
fi
assert_contains "$launchctl_log" "bootout gui/$(id -u) $installed_plist"
assert_contains "$install_output" 'Logs retained at'

reset_test_home
run_installer
printf 'foreign checker\n' > "$installed_checker"
: > "$launchctl_log"
if run_uninstaller; then
  printf 'FAIL: uninstaller should report an unmarked checker\n' >&2
  exit 1
fi
if [[ "$(< "$installed_checker")" != 'foreign checker' ]]; then
  printf 'FAIL: uninstaller changed an unmarked checker\n' >&2
  exit 1
fi
if [[ ! -f "$installed_plist" ]]; then
  printf 'FAIL: uninstaller changed files after a preflight collision\n' >&2
  exit 1
fi
assert_contains "$install_output" 'refusing to remove unmarked file'

printf 'Update prompt tests passed: 11 cases\n'
