#!/usr/bin/env bash
# Managed by shereef-skills update prompt

set -euo pipefail

marker='Managed by shereef-skills update prompt'
label='com.shereef-skills.update-check'
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
source_checker="$script_dir/check-for-updates.sh"
support_dir="$HOME/Library/Application Support/Shereef Skills"
launch_agents_dir="$HOME/Library/LaunchAgents"
logs_dir="$HOME/Library/Logs/Shereef Skills"
installed_checker="$support_dir/check-for-updates.sh"
plist="$launch_agents_dir/$label.plist"
stdout_log="$logs_dir/update-check.log"
stderr_log="$logs_dir/update-check.error.log"

fail() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

xml_escape() {
  local value="$1"
  value="${value//&/&amp;}"
  value="${value//</&lt;}"
  value="${value//>/&gt;}"
  value="${value//\"/&quot;}"
  value="${value//\'/&apos;}"
  printf '%s' "$value"
}

require_replaceable() {
  local target="$1"
  if [[ -L "$target" ]]; then
    fail "refusing to replace symlink: $target"
  fi
  if [[ -e "$target" ]] && ! grep -Fq "$marker" "$target"; then
    fail "refusing to replace unmarked file: $target"
  fi
}

[[ "$(uname -s)" == 'Darwin' ]] || fail 'the update prompt installer supports macOS only'
[[ -f "$source_checker" ]] || fail "checker was not found: $source_checker"
command -v launchctl >/dev/null 2>&1 || fail 'launchctl is required'

require_replaceable "$installed_checker"
require_replaceable "$plist"

mkdir -p "$support_dir" "$launch_agents_dir" "$logs_dir"
cp "$source_checker" "$installed_checker"
chmod +x "$installed_checker"

escaped_checker="$(xml_escape "$installed_checker")"
escaped_stdout="$(xml_escape "$stdout_log")"
escaped_stderr="$(xml_escape "$stderr_log")"
plist_tmp="$(mktemp "$plist.tmp.XXXXXX")"
trap 'rm -f "$plist_tmp"' EXIT

{
  printf '%s\n' '<?xml version="1.0" encoding="UTF-8"?>'
  printf '%s\n' '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">'
  printf '%s\n' '<plist version="1.0">'
  printf '%s\n' '<dict>'
  printf '  <!-- %s -->\n' "$marker"
  printf '%s\n' '  <key>Label</key>'
  printf '  <string>%s</string>\n' "$label"
  printf '%s\n' '  <key>ProgramArguments</key>'
  printf '%s\n' '  <array>'
  printf '    <string>%s</string>\n' "$escaped_checker"
  printf '%s\n' '    <string>--notify</string>'
  printf '%s\n' '  </array>'
  printf '%s\n' '  <key>StartCalendarInterval</key>'
  printf '%s\n' '  <dict>'
  printf '%s\n' '    <key>Weekday</key><integer>1</integer>'
  printf '%s\n' '    <key>Hour</key><integer>10</integer>'
  printf '%s\n' '  </dict>'
  printf '%s\n' '  <key>EnvironmentVariables</key>'
  printf '%s\n' '  <dict>'
  printf '%s\n' '    <key>PATH</key>'
  printf '%s\n' '    <string>/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin</string>'
  printf '%s\n' '  </dict>'
  printf '%s\n' '  <key>StandardOutPath</key>'
  printf '  <string>%s</string>\n' "$escaped_stdout"
  printf '%s\n' '  <key>StandardErrorPath</key>'
  printf '  <string>%s</string>\n' "$escaped_stderr"
  printf '%s\n' '</dict>'
  printf '%s\n' '</plist>'
} > "$plist_tmp"

mv "$plist_tmp" "$plist"
trap - EXIT

launchctl bootout "gui/$UID" "$plist" >/dev/null 2>&1 || true
launchctl bootstrap "gui/$UID" "$plist"

printf 'Installed weekly update prompt: Mondays at 10:00 local time.\n'
printf 'Update command: npx skills@latest update --global increase-test-coverage\n'
printf 'Launch agent: %s\n' "$plist"
