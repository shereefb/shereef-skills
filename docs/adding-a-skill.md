# Adding a skill

Keep every workflow in one canonical directory. Do not create separate Claude Code and Codex copies.

## 1. Create the skill directory

Use a lowercase, hyphenated name:

```text
skills/<skill-name>/
├── SKILL.md
├── agents/
│   └── openai.yaml
└── references/
```

Create only the optional directories the skill needs. Put executable helpers in `scripts/` and output templates in `assets/`.

## 2. Use portable frontmatter

Every `SKILL.md` starts with:

```yaml
---
name: skill-name
description: Use when the task matches a precise trigger and scope.
---
```

The `name` must match its directory. Keep shared frontmatter within the [Agent Skills specification](https://agentskills.io/specification). Put Codex interface metadata in `agents/openai.yaml`. Do not add Claude-only invocation fields to a skill that must also validate in Codex.

## 3. Keep supporting material focused

Link every reference from `SKILL.md` where the agent needs it. Use relative links from the skill directory. Avoid duplicated instructions, narrative history, and resources that no workflow reads.

## 4. Register the skill

Add the skill to:

1. the catalog in [`README.md`](../README.md);
2. the `skills` array in [`.claude-plugin/marketplace.json`](../.claude-plugin/marketplace.json).

Use the exact path `./skills/<skill-name>` in the marketplace manifest.

## 5. Validate before committing

Run:

```bash
bash tests/validate.sh
bash scripts/validate.sh
DISABLE_TELEMETRY=1 npx skills@latest add . --list
claude plugin validate . --strict
git diff --check
```

The Claude command requires Claude Code. If it is unavailable, record the skipped host-specific validation rather than claiming it passed.

Test installation in a temporary Git repository before publishing. Target both agents, use project scope, and use `--copy` so the test does not touch user-level skill directories:

```bash
npx skills@latest add /absolute/path/to/shereef-skills \
  --agent claude-code \
  --agent codex \
  --skill <skill-name> \
  --copy \
  --yes
```

Confirm both installed `SKILL.md` files match the canonical source.

## 6. Commit one reviewable change

Commit the skill, catalog entry, marketplace entry, and any focused validation changes together. Do not mix unrelated skill rewrites into the same commit.
