# Skill update prompts implementation plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add an opt-in weekly macOS notification when the installed `increase-test-coverage` skill differs from its source on GitHub.

**Architecture:** A read-only shell checker parses the universal installer's lock file with Node.js, fetches the repository tree with `curl`, and compares folder hashes. Two macOS lifecycle scripts install or remove a marked per-user launch agent without touching foreign files. Shell fixtures isolate the home directory and fake network, notification, and launch-agent commands.

**Tech Stack:** Bash, Node.js, `curl`, macOS `launchd`, AppleScript notifications, GitHub Trees API.

## Global constraints

- The checker never changes an installed skill.
- Automatic skill updates remain out of scope.
- The scheduled check runs every Monday at 10:00 in the user's local time.
- Managed files use the marker `Managed by shereef-skills update prompt`.
- An existing unmarked target stops installation or removal without changing that target.
- The uninstaller retains updater log files.
- No new package dependency is added.

---

### Task 1: Add the read-only update checker

**Files:**
- Create: `tests/update-prompts.sh`
- Create: `scripts/check-for-updates.sh`

**Interfaces:**
- Consumes: `~/.agents/.skill-lock.json`, `SHEREEF_SKILLS_LOCK_FILE`, `SHEREEF_SKILLS_API_URL`, `curl`, `node`, and optional `--notify`.
- Produces: exit `0` when current, exit `10` when an update exists, exit `1` when the check cannot run. With `--notify`, an available update calls `osascript` once.

- [ ] **Step 1: Write failing checker fixtures**

Create a fixture runner that writes lock and GitHub tree JSON under a temporary directory. Put fake `curl` and `osascript` executables first on `PATH`. Assert that matching hashes print `increase-test-coverage is up to date` and exit `0`, differing hashes print the manual update command and exit `10`, and `--notify` records one `osascript` call. Add cases for missing lock entries, a foreign source, failed `curl`, and a response without the skill directory.

The fixture lock entry must use this shape:

```json
{
  "skills": {
    "increase-test-coverage": {
      "source": "shereefb/shereef-skills",
      "skillPath": "skills/increase-test-coverage/SKILL.md",
      "skillFolderHash": "installed-hash"
    }
  }
}
```

The upstream fixture must use this shape:

```json
{
  "tree": [
    {
      "path": "skills/increase-test-coverage",
      "mode": "040000",
      "type": "tree",
      "sha": "installed-hash"
    }
  ]
}
```

- [ ] **Step 2: Run the checker fixtures and verify red**

Run:

```bash
bash tests/update-prompts.sh
```

Expected: nonzero with `scripts/check-for-updates.sh is missing`.

- [ ] **Step 3: Implement the checker**

Create `scripts/check-for-updates.sh` with `set -euo pipefail`. Resolve the lock file from `SHEREEF_SKILLS_LOCK_FILE` or `$HOME/.agents/.skill-lock.json`. Resolve the API URL from `SHEREEF_SKILLS_API_URL` or `https://api.github.com/repos/shereefb/shereef-skills/git/trees/main?recursive=1`.

Use one Node.js expression to read and validate the lock entry, returning tab-separated source, skill path, installed hash, and skill name. Reject any source other than `shereefb/shereef-skills`. Fetch the upstream tree with:

```bash
curl --fail --silent --show-error --location \
  --connect-timeout 5 --max-time 15 \
  --header 'Accept: application/vnd.github+json' \
  --header 'X-GitHub-Api-Version: 2022-11-28' \
  --user-agent 'shereef-skills-update-prompt/1' \
  "$api_url"
```

Use Node.js to find the tree entry whose path equals the directory containing `skillPath`. Compare its SHA with `skillFolderHash`. On a difference, print:

```text
Update available for increase-test-coverage.
Run: npx skills@latest update --global increase-test-coverage
```

If `--notify` is present, call `osascript` with a notification whose title is `Shereef Skills update available` and whose body contains the skill name and update command. Treat unsupported arguments, missing dependencies, invalid JSON, missing entries, and network failures as exit `1` with one descriptive stderr line.

- [ ] **Step 4: Run checker fixtures and verify green**

Run:

```bash
bash tests/update-prompts.sh
```

Expected: exit `0` with a checker case summary.

- [ ] **Step 5: Commit the checker**

```bash
git add scripts/check-for-updates.sh tests/update-prompts.sh
git commit -m "feat: check installed skills for updates"
```

### Task 2: Add safe macOS installation and removal

**Files:**
- Modify: `tests/update-prompts.sh`
- Create: `scripts/install-update-prompt-macos.sh`
- Create: `scripts/uninstall-update-prompt-macos.sh`

**Interfaces:**
- Consumes: the checker from Task 1, `$HOME`, `uname`, and `launchctl`.
- Produces: a marked checker at `~/Library/Application Support/Shereef Skills/check-for-updates.sh` and a marked launch agent at `~/Library/LaunchAgents/com.shereef-skills.update-check.plist`.

- [ ] **Step 1: Add failing lifecycle fixtures**

Extend `tests/update-prompts.sh` with a fake `uname` that prints `Darwin` and a fake `launchctl` that records its arguments. Run the installer with a temporary `HOME` and assert:

```text
Library/Application Support/Shereef Skills/check-for-updates.sh
Library/LaunchAgents/com.shereef-skills.update-check.plist
```

exist, include the management marker, and contain the temporary absolute paths. Assert that the plist contains `Weekday` value `1`, `Hour` value `10`, `--notify`, `StandardOutPath`, and `StandardErrorPath`. Assert that `launchctl` receives `bootstrap gui/<uid> <plist-path>`.

Add a collision case that places an unmarked plist at the target and expects installation to fail without changing it. Add uninstall cases that remove marked targets, retain logs, call `bootout`, and preserve an unmarked checker.

- [ ] **Step 2: Run lifecycle fixtures and verify red**

Run:

```bash
bash tests/update-prompts.sh
```

Expected: nonzero because the installer and uninstaller do not exist.

- [ ] **Step 3: Implement the installer**

Create `scripts/install-update-prompt-macos.sh` with `set -euo pipefail`. Require `uname -s` to equal `Darwin`. Resolve the source checker relative to the installer. Create only these directories:

```text
$HOME/Library/Application Support/Shereef Skills
$HOME/Library/LaunchAgents
$HOME/Library/Logs/Shereef Skills
```

Before writing the checker or plist, allow a missing target or a target containing `Managed by shereef-skills update prompt`. Reject any other existing target. Copy the checker and make it executable. Write a property list containing:

```xml
<key>Label</key>
<string>com.shereef-skills.update-check</string>
<key>ProgramArguments</key>
<array>
  <string>CHECKER_ABSOLUTE_PATH</string>
  <string>--notify</string>
</array>
<key>StartCalendarInterval</key>
<dict>
  <key>Weekday</key><integer>1</integer>
  <key>Hour</key><integer>10</integer>
</dict>
```

Add an environment PATH of `/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin`, plus absolute stdout and stderr log paths. Escape `&`, `<`, `>`, `'`, and `"` in all inserted XML values. Run `launchctl bootout gui/$UID "$plist"` without failing when no prior job exists, then run `launchctl bootstrap gui/$UID "$plist"`.

- [ ] **Step 4: Implement the uninstaller**

Create `scripts/uninstall-update-prompt-macos.sh` with `set -euo pipefail`. Require macOS. For each managed target, remove it only if it contains the marker. Call `launchctl bootout gui/$UID "$plist"` before removing a marked plist and tolerate an unloaded job. Leave the log directory intact and print its location.

- [ ] **Step 5: Run lifecycle fixtures and verify green**

Run:

```bash
bash tests/update-prompts.sh
```

Expected: exit `0` with checker and lifecycle case counts.

- [ ] **Step 6: Commit the lifecycle scripts**

```bash
git add scripts/install-update-prompt-macos.sh scripts/uninstall-update-prompt-macos.sh tests/update-prompts.sh
git commit -m "feat: add weekly macOS skill update prompts"
```

### Task 3: Document and validate the update prompt

**Files:**
- Modify: `README.md`
- Modify: `.github/workflows/validate.yml`

**Interfaces:**
- Consumes: all scripts and fixtures from Tasks 1 and 2.
- Produces: user instructions and CI execution of `tests/update-prompts.sh`.

- [ ] **Step 1: Add README instructions**

Under `Update or remove`, document the manual read-only check:

```bash
bash scripts/check-for-updates.sh
```

Document opt-in weekly prompts:

```bash
bash scripts/install-update-prompt-macos.sh
```

State that the prompt runs Mondays at 10:00 local time, stays quiet when current, and never installs an update. Keep the existing manual update command. Document removal:

```bash
bash scripts/uninstall-update-prompt-macos.sh
```

State that removal retains logs under `~/Library/Logs/Shereef Skills`.

- [ ] **Step 2: Add the fixture test to CI**

Add a GitHub Actions step after the validator fixture step:

```yaml
- name: Test update prompts
  run: bash tests/update-prompts.sh
```

The fixtures fake macOS commands, so this test remains runnable on Ubuntu.

- [ ] **Step 3: Run the complete gate**

Run:

```bash
bash tests/update-prompts.sh
bash tests/validate.sh
bash scripts/validate.sh
DISABLE_TELEMETRY=1 npx skills@latest add . --list
git diff --check
```

Expected: every command exits `0`; the updater fixtures report all cases passed; repository validation reports one skill; discovery lists `increase-test-coverage`; and `git diff --check` prints nothing.

- [ ] **Step 4: Review the final diff against the approved spec**

Run:

```bash
git diff HEAD~2 -- README.md .github/workflows/validate.yml scripts tests docs/superpowers
git status --short
```

Confirm every success criterion in `docs/superpowers/specs/2026-09-20-skill-update-prompts-design.md` has direct code, test, or documentation evidence and no unrelated file changed.

- [ ] **Step 5: Commit the documentation and CI wiring**

```bash
git add README.md .github/workflows/validate.yml
git commit -m "docs: explain skill update prompts"
```
