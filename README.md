# Shereef Skills

Reusable agent skills for Claude Code, OpenAI Codex, and other tools that support the [Agent Skills specification](https://agentskills.io/specification).

This repository keeps one canonical copy of each skill under [`skills/`](skills/). Host-specific packaging stays outside the portable `SKILL.md` files.

## Skills

### increase-test-coverage

Runs one strategic test-coverage wave. It selects a coherent, high-value behavior matrix using consequence, recent churn, coverage gaps, contract strength, and test cost. It writes tests at the smallest faithful layer, avoids routine full integration and end-to-end runs, validates suspected bugs independently, searches for adjacent defect patterns, and files confirmed bugs in Linear as Ready to Build with the correct milestone.

[Read the skill](skills/increase-test-coverage/SKILL.md)

## Install for Claude Code and Codex

First inspect the skills the repository exposes:

```bash
npx skills@latest add shereefb/shereef-skills --list
```

Install every skill globally for both agents:

```bash
npx skills@latest add shereefb/shereef-skills \
  --global \
  --agent claude-code \
  --agent codex \
  --skill '*'
```

The installer shows its selected destinations and asks before replacing an existing entry. Review collision warnings instead of accepting them blindly. The [`skills` CLI](https://github.com/vercel-labs/skills) manages the host-specific paths and shared copies.

Restart an agent if a newly installed skill does not appear in its skill list.

## Invoke the skill

Claude Code:

```text
/increase-test-coverage Run one strategic coverage wave in this repository.
```

Codex:

```text
$increase-test-coverage Run one strategic coverage wave in this repository.
```

Each invocation creates at most one pull request and stops. When using an outer loop, wait for that pull request to land and for `main` to change before starting the next wave.

## Optional Claude Code plugin

Claude Code can install this collection as a namespaced plugin instead of a plain global skill:

```text
/plugin marketplace add shereefb/shereef-skills
/plugin install shereef-skills@shereef-skills
```

The plugin invocation is namespaced:

```text
/shereef-skills:increase-test-coverage
```

Choose either the universal Claude Code installation or the Claude plugin. Installing both exposes the same workflow twice.

## Update or remove

Check this collection for an available update from a repository checkout:

```bash
bash scripts/check-for-updates.sh
```

Update the global skill installed through the `skills` CLI:

```bash
npx skills@latest update --global increase-test-coverage
```

### Optional weekly update prompt on macOS

Install a per-user update prompt from a repository checkout:

```bash
bash scripts/install-update-prompt-macos.sh
```

The installer copies the checker into `~/Library/Application Support/Shereef Skills`
and creates a launch agent that runs every Monday at 10:00 in your local time.
It stays quiet when the installed skill is current. When an update exists, it
shows the manual update command. It never changes an installed skill.

The checkout is not required after installation. Remove the prompt with:

```bash
bash scripts/uninstall-update-prompt-macos.sh
```

Removal keeps diagnostic logs under `~/Library/Logs/Shereef Skills`.

Remove it from both agents:

```bash
npx skills@latest remove \
  --global \
  --agent claude-code \
  --agent codex \
  increase-test-coverage
```

For a Claude plugin installation, update or remove it inside Claude Code:

```text
/plugin marketplace update shereef-skills
/plugin update shereef-skills@shereef-skills
/plugin uninstall shereef-skills@shereef-skills
```

## Prompt for another machine

Give this prompt to an agent that has shell and GitHub access:

```text
Install or update the public agent skills from https://github.com/shereefb/shereef-skills for both Claude Code and OpenAI Codex on this machine.

First inspect the repository, README, skill files, and current official installation guidance before running an installer. List the skills exposed by the repository. Inventory the existing user-level Claude Code and Codex skills and identify any same-named files, directories, or symlinks.

Use the repository's documented universal installation method. Install all skills globally for the claude-code and codex targets. Do not also install the Claude marketplace plugin, because that would expose duplicate Claude skills. Do not create a second Codex copy in a legacy directory when the current installer already manages the skill.

Preserve existing work. If a destination is a real file, a real directory, or a symlink to another source, do not overwrite or delete it. Stop and report the exact conflict. Only refresh entries that the installer can prove belong to this repository. Do not change unrelated global settings.

After installation, validate each SKILL.md and supporting reference, confirm that Claude Code and Codex can discover increase-test-coverage, and report the source commit, installed paths, validation commands, and any restart or reload needed.
```

## Validate the repository

Run the fixture tests and repository validator:

```bash
bash tests/validate.sh
bash scripts/validate.sh
```

Check discovery with the same public installer used by consumers:

```bash
DISABLE_TELEMETRY=1 npx skills@latest add . --list
```

When Claude Code is installed, validate its marketplace metadata:

```bash
claude plugin validate . --strict
```

## Add another skill

Read [Adding a skill](docs/adding-a-skill.md). New skills use one directory under `skills/`, portable frontmatter, focused references, a catalog entry here, a Claude marketplace entry, and the same validation gate.

## Sources and compatibility

- [Claude Code skills](https://code.claude.com/docs/en/skills)
- [Claude Code plugin marketplaces](https://code.claude.com/docs/en/plugin-marketplaces)
- [OpenAI skill documentation](https://learn.chatgpt.com/docs/build-skills)
- [Agent Skills specification](https://agentskills.io/specification)
- [Vercel skills CLI](https://github.com/vercel-labs/skills)

## License

[MIT](LICENSE)
