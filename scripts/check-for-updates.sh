#!/usr/bin/env bash
# Managed by shereef-skills update prompt

set -euo pipefail

skill_name='increase-test-coverage'
expected_source='shereefb/shereef-skills'
update_command='npx skills@latest update --global increase-test-coverage'
lock_file="${SHEREEF_SKILLS_LOCK_FILE:-$HOME/.agents/.skill-lock.json}"
api_url="${SHEREEF_SKILLS_API_URL:-https://api.github.com/repos/shereefb/shereef-skills/git/trees/main?recursive=1}"
notify=0

fail() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

case "${1:-}" in
  '')
    ;;
  --notify)
    notify=1
    ;;
  *)
    fail "unsupported argument: $1"
    ;;
esac

if [[ $# -gt 1 ]]; then
  fail 'expected no arguments or --notify'
fi

command -v node >/dev/null 2>&1 || fail 'node is required'
command -v curl >/dev/null 2>&1 || fail 'curl is required'
[[ -f "$lock_file" ]] || fail "skill lock file was not found: $lock_file"

if ! lock_values="$(node -e '
  const fs = require("fs");
  const path = require("path").posix;
  const lockPath = process.argv[1];
  const skillName = process.argv[2];
  let data;
  try {
    data = JSON.parse(fs.readFileSync(lockPath, "utf8"));
  } catch (error) {
    console.error(`could not read the skill lock file: ${error.message}`);
    process.exit(1);
  }
  const entry = data.skills && data.skills[skillName];
  if (!entry) {
    console.error(`${skillName} is not recorded in ${lockPath}`);
    process.exit(1);
  }
  for (const field of ["source", "skillPath", "skillFolderHash"]) {
    if (typeof entry[field] !== "string" || entry[field].length === 0) {
      console.error(`${skillName} has no ${field} in ${lockPath}`);
      process.exit(1);
    }
  }
  process.stdout.write([
    entry.source,
    path.dirname(entry.skillPath),
    entry.skillFolderHash,
    skillName,
  ].join("\t"));
' "$lock_file" "$skill_name" 2>&1)"; then
  fail "$lock_values"
fi

IFS=$'\t' read -r source skill_directory installed_hash locked_skill_name <<< "$lock_values"

if [[ "$source" != "$expected_source" ]]; then
  fail "$skill_name has unexpected source '$source'; expected '$expected_source'"
fi

if ! api_response="$(curl --fail --silent --show-error --location \
  --connect-timeout 5 --max-time 15 \
  --header 'Accept: application/vnd.github+json' \
  --header 'X-GitHub-Api-Version: 2022-11-28' \
  --user-agent 'shereef-skills-update-prompt/1' \
  "$api_url")"; then
  fail 'could not fetch the GitHub tree'
fi

if ! upstream_hash="$(printf '%s' "$api_response" | node -e '
  const fs = require("fs");
  const target = process.argv[1];
  let data;
  try {
    data = JSON.parse(fs.readFileSync(0, "utf8"));
  } catch (error) {
    console.error(`could not parse the GitHub tree: ${error.message}`);
    process.exit(1);
  }
  const entry = Array.isArray(data.tree)
    ? data.tree.find((item) => item && item.type === "tree" && item.path === target)
    : undefined;
  if (!entry || typeof entry.sha !== "string" || entry.sha.length === 0) {
    console.error(`skill directory was not found in the GitHub tree: ${target}`);
    process.exit(1);
  }
  process.stdout.write(entry.sha);
' "$skill_directory" 2>&1)"; then
  fail "$upstream_hash"
fi

if [[ "$installed_hash" == "$upstream_hash" ]]; then
  if [[ $notify -eq 0 ]]; then
    printf '%s is up to date.\n' "$locked_skill_name"
  fi
  exit 0
fi

printf 'Update available for %s.\n' "$locked_skill_name"
printf 'Run: %s\n' "$update_command"

if [[ $notify -eq 1 ]]; then
  command -v osascript >/dev/null 2>&1 || fail 'osascript is required for --notify'
  osascript -e "display notification \"Run: $update_command\" with title \"Shereef Skills update available\" subtitle \"$locked_skill_name\""
fi

exit 10
