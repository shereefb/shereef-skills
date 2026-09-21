# Shereef Skills repository design

Date: 2026-09-20
Status: Approved in conversation, pending written-spec review

## Goal

Create a public repository at `github.com/shereefb/shereef-skills` that stores
Shereef's reusable agent skills in one canonical tree. The first published skill
is `increase-test-coverage`. People must be able to install the collection for
Claude Code and OpenAI Codex on another machine without maintaining separate
skill bodies.

## Scope

The first release includes:

- one portable `increase-test-coverage` skill with its references and optional
  Codex UI metadata;
- a public MIT license;
- a README with installation, invocation, update, validation, and contribution
  instructions;
- a copy-paste prompt that tells an agent how to install the collection for
  Claude Code and Codex safely;
- an optional Claude Code marketplace manifest;
- repository validation that checks structure, metadata, references, and skill
  discovery.

The first release does not publish to a hosted marketplace, add an MCP server,
modify Claude or Codex settings, or create a custom package manager.

## Repository structure

```text
shereef-skills/
├── .claude-plugin/
│   └── marketplace.json
├── .github/
│   └── workflows/
│       └── validate.yml
├── docs/
│   └── adding-a-skill.md
├── scripts/
│   └── validate.sh
├── skills/
│   └── increase-test-coverage/
│       ├── SKILL.md
│       ├── agents/
│       │   └── openai.yaml
│       └── references/
├── LICENSE
└── README.md
```

`skills/<name>/` is the only source of each workflow. Claude Code and Codex use
the same `SKILL.md` and supporting files. Host-specific packaging and UI metadata
stay outside portable skill frontmatter.

## Distribution

The primary cross-host installation path uses the open `skills` CLI:

```bash
npx skills@latest add shereefb/shereef-skills \
  --global \
  --agent claude-code \
  --agent codex \
  --skill '*'
```

The README also documents Claude Code's native plugin path:

```text
/plugin marketplace add shereefb/shereef-skills
/plugin install shereef-skills@shereef-skills
```

Users choose one Claude installation method. Installing both would expose the
same skill twice under different sources. Codex uses the universal installer for
this release. A Codex plugin can be added later without changing the canonical
skill tree.

The design follows the shared Agent Skills directory format documented by
[Claude Code](https://code.claude.com/docs/en/skills),
[OpenAI](https://learn.chatgpt.com/docs/build-skills), and the
[Agent Skills specification](https://agentskills.io/specification). The
cross-host command follows the installation model used by the
[Vercel skills CLI](https://github.com/vercel-labs/skills).

## Cross-machine agent prompt

The README provides a prompt that instructs an agent to:

1. inspect the public repository and its installation instructions;
2. list the skills before installing them;
3. inventory existing Claude Code and Codex skill destinations;
4. stop on a foreign file, directory, or symlink collision;
5. install the selected collection globally for both hosts;
6. avoid a duplicate Codex copy in a legacy location;
7. validate skill discovery and report the installed commit and paths;
8. leave unrelated global settings unchanged.

The prompt does not tell an agent to run remote shell content blindly.

## Validation

`scripts/validate.sh` runs without changing user configuration. It checks:

- each immediate directory under `skills/` contains `SKILL.md`;
- each skill has portable `name` and `description` frontmatter;
- the frontmatter name matches the directory name;
- every local Markdown reference from `SKILL.md` resolves;
- `agents/openai.yaml` parses when present;
- `.claude-plugin/marketplace.json` parses and lists existing skill paths;
- no `TODO`, `FIXME`, or scaffold placeholder remains in published files;
- the `skills` CLI can discover the repository.

GitHub Actions runs the same script on pushes and pull requests. Local
verification also runs Claude's strict plugin validator when the Claude CLI is
available. The absence of that optional CLI does not make the portable checks
pass silently; the report identifies the skipped host-specific check.

## Adding future skills

Every new skill requires:

1. one directory at `skills/<name>/`;
2. portable `SKILL.md` frontmatter;
3. directly linked supporting files only when needed;
4. a README catalog entry;
5. a Claude marketplace manifest entry;
6. local and CI validation.

Claude-only frontmatter must not be added to a shared skill merely for
invocation control. Codex-specific interface metadata belongs in
`agents/openai.yaml`. If a future skill genuinely needs host-specific behavior,
document and validate each host's metadata separately rather than weakening one
host to satisfy the other.

## Publishing sequence

1. Commit this approved design.
2. Add the repository files and copied skill in a separate implementation
   commit.
3. Run portable validation and host-specific validation where available.
4. Test installation in temporary homes for Claude Code and Codex without
   touching the user's live skill directories.
5. Create the public GitHub repository under `shereefb`.
6. Push `main` and verify repository visibility, default branch, files, and
   clone access from GitHub.

## Success criteria

- `https://github.com/shereefb/shereef-skills` is public and cloneable.
- The repository contains one canonical `increase-test-coverage` skill.
- Claude Code and Codex installation instructions point to supported user-level
  destinations through the universal installer.
- The copy-paste agent prompt has collision and verification safeguards.
- Local validation and GitHub Actions pass.
- The README explains how to invoke, update, inspect, and extend the collection.
