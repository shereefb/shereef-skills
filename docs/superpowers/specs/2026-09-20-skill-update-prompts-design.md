# Skill update prompts design

Date: 2026-09-20
Status: Approved in conversation, pending written-spec review

## Goal

Give macOS users an opt-in weekly notification when an installed skill from
`shereefb/shereef-skills` has changed upstream. Keep the check read-only. The
user chooses when to run the existing `skills update` command.

## Scope

Add three repository scripts:

- `scripts/check-for-updates.sh` compares the installed skill-folder hash with
  the current folder hash on GitHub and can display a macOS notification.
- `scripts/install-update-prompt-macos.sh` installs the checker and a weekly
  per-user launch agent.
- `scripts/uninstall-update-prompt-macos.sh` unloads that launch agent and
  removes only files managed by this repository.

Update the README with setup, manual-check, update, and removal commands. Add
fixture tests for the checker and lifecycle scripts.

This change does not silently update a skill, add a background service outside
macOS `launchd`, or change Claude Code or Codex settings.

## Update check

The universal `skills` installer records each global installation in
`~/.agents/.skill-lock.json`. The entry contains the GitHub source, path to the
skill's `SKILL.md`, and the installed skill-folder tree hash.

The checker will:

1. locate the `increase-test-coverage` entry in the lock file;
2. require the expected source, `shereefb/shereef-skills`;
3. derive the skill directory from the recorded `SKILL.md` path;
4. query the GitHub tree API for the repository's default branch;
5. compare the upstream directory tree hash with `skillFolderHash`;
6. print one of three results: current, update available, or unable to check.

An available update exits with a distinct status so tests and future callers
can distinguish it from success and operational failure. With `--notify`, the
checker calls macOS `osascript` only when an update is available. The
notification names the skill and shows the manual update command.

The script will use `node` to parse JSON because the documented installer
already requires `npx`. It will use macOS `curl` for the GitHub request. The
launch agent will receive a PATH that covers Apple Silicon Homebrew, Intel
Homebrew, and system binaries.

## Installation and removal

The installer will support macOS only and install these per-user files:

```text
~/Library/Application Support/Shereef Skills/check-for-updates.sh
~/Library/LaunchAgents/com.shereef-skills.update-check.plist
~/Library/Logs/Shereef Skills/update-check.log
~/Library/Logs/Shereef Skills/update-check.error.log
```

The launch agent will run every Monday at 10:00 in the user's local time. The
installer will copy the checker, write the property list with absolute paths,
load it with `launchctl bootstrap`, and print the installed schedule and manual
update command.

Managed files will contain a stable marker. Reinstallation may replace marked
files from this updater. If an exact target exists without the marker, the
installer will stop and report the collision.

The uninstaller will use `launchctl bootout` when the job is loaded, then remove
the marked checker and property list by exact path. It will retain log files so
the removal remains auditable and report their location. An unmarked target is
left untouched and reported.

## Errors and notifications

Scheduled checks stay quiet when the installed skill is current. Network,
GitHub, lock-file, and dependency failures go to the launch agent error log and
do not display a desktop notification. This prevents recurring prompts for a
temporary operational problem.

The GitHub request will set a short timeout and a descriptive user agent. It
will use unauthenticated public API access because the repository is public and
the job runs once per week.

## Tests

Shell fixture tests will use temporary homes and fake external commands. They
will cover:

- matching folder hashes;
- an available update with and without `--notify`;
- missing and foreign lock entries;
- malformed GitHub responses and failed requests;
- installer output, property-list contents, and collision protection;
- uninstaller cleanup and preservation of unmarked files.

The repository gate remains:

```bash
bash tests/validate.sh
bash scripts/validate.sh
git diff --check
```

The update-prompt fixture test will also run directly as part of
`tests/validate.sh` so CI exercises it.

## Success criteria

- A macOS user can opt into one weekly update notification with one installer
  command.
- A current installation produces no notification.
- The checker never changes installed skills.
- The notification provides the exact manual update command.
- Reinstallation is safe, removal is exact, and foreign target files survive.
- All fixture tests and repository validation pass.
