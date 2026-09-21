#!/usr/bin/env bash
# Managed by shereef-skills update prompt

set -euo pipefail

marker='Managed by shereef-skills update prompt'
label='com.shereef-skills.update-check'
support_dir="$HOME/Library/Application Support/Shereef Skills"
logs_dir="$HOME/Library/Logs/Shereef Skills"
installed_checker="$support_dir/check-for-updates.sh"
plist="$HOME/Library/LaunchAgents/$label.plist"

fail() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

require_managed_or_missing() {
  local target="$1"
  if [[ -e "$target" ]] && ! grep -Fq "$marker" "$target"; then
    fail "refusing to remove unmarked file: $target"
  fi
}

[[ "$(uname -s)" == 'Darwin' ]] || fail 'the update prompt uninstaller supports macOS only'
command -v launchctl >/dev/null 2>&1 || fail 'launchctl is required'

require_managed_or_missing "$installed_checker"
require_managed_or_missing "$plist"

if [[ -f "$plist" ]]; then
  launchctl bootout "gui/$UID" "$plist" >/dev/null 2>&1 || true
fi

rm -f "$installed_checker" "$plist"

printf 'Removed the Shereef Skills update prompt.\n'
printf 'Logs retained at: %s\n' "$logs_dir"
