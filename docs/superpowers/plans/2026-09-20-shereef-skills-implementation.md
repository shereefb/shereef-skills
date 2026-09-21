# Shereef Skills implementation plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Publish a validated public skills collection containing `increase-test-coverage`, installable by Claude Code and OpenAI Codex from one canonical source.

**Architecture:** Store portable skills under `skills/<name>/`. Use the Vercel `skills` CLI as the primary cross-host installer and a Claude marketplace manifest as an optional native Claude path. A dependency-light shell validator checks repository structure and delegates discovery to the public CLI.

**Tech Stack:** Agent Skills Markdown, POSIX shell, Ruby standard-library YAML parsing, JSON, GitHub Actions, Git, GitHub CLI, Vercel `skills` CLI.

## Global constraints

- The GitHub repository is public and named `shereefb/shereef-skills`.
- The local checkout is `/Users/jarvis/Documents/code/shereef-skills`.
- MIT is the license.
- `skills/increase-test-coverage/` is the only canonical copy of the first skill.
- Shared `SKILL.md` frontmatter stays portable; Codex UI metadata remains in `agents/openai.yaml`.
- The primary installer supports both `claude-code` and `codex` without changing unrelated settings.
- Installation tests must not touch live user skill directories.
- Existing foreign skill destinations are never silently overwritten.

---

### Task 1: Add repository validation with failure fixtures

**Files:**
- Create: `scripts/validate.sh`
- Create: `tests/validate.sh`

**Interfaces:**
- Consumes: repository root as optional argument, defaulting to the parent of `scripts/`.
- Produces: `bash scripts/validate.sh [repo-root]`, exit `0` with `Validation passed: N skill(s)` or nonzero with specific errors.

- [ ] **Step 1: Write the validator test before the validator**

The test creates temporary repositories and asserts that validation fails when `scripts/validate.sh` is absent, then later covers a valid skill, a directory/name mismatch, a broken Markdown reference, an unlisted marketplace skill, and a published placeholder.

Run:

```bash
bash tests/validate.sh
```

Expected before implementation: nonzero with `scripts/validate.sh: No such file or directory`.

- [ ] **Step 2: Implement the minimal validator**

The script must:

```text
1. Resolve the supplied repository root.
2. Require skills/, .claude-plugin/marketplace.json, and at least one skills/*/SKILL.md.
3. Extract name and description from the first YAML frontmatter block.
4. Require the name to equal the containing directory.
5. Check local Markdown links from each SKILL.md.
6. Parse agents/openai.yaml with Ruby YAML when present.
7. Parse marketplace.json and verify every listed skill path exists.
8. Require every skills/* directory to appear in the marketplace manifest.
9. Reject unfinished scaffold markers in published files.
10. Print a stable success summary.
```

- [ ] **Step 3: Run validator tests**

Run:

```bash
bash tests/validate.sh
```

Expected: all fixture cases pass and exit `0`.

- [ ] **Step 4: Commit the validator**

```bash
git add scripts/validate.sh tests/validate.sh
git commit -m "test: add portable skill repository validation"
```

### Task 2: Add the first canonical skill and package metadata

**Files:**
- Create: `skills/increase-test-coverage/SKILL.md`
- Create: `skills/increase-test-coverage/agents/openai.yaml`
- Create: `skills/increase-test-coverage/references/target-selection.md`
- Create: `skills/increase-test-coverage/references/execution-and-verification.md`
- Create: `skills/increase-test-coverage/references/bug-validation-and-linear.md`
- Create: `.claude-plugin/marketplace.json`
- Create: `LICENSE`

**Interfaces:**
- Consumes: the validated personal skill at `/Users/jarvis/.codex/skills/increase-test-coverage`.
- Produces: one portable skill discovered as `increase-test-coverage`, one Claude plugin named `shereef-skills`, and MIT licensing.

- [ ] **Step 1: Add the validated skill verbatim**

Copy the approved `SKILL.md`, `references/`, and `agents/openai.yaml` contents into the canonical repository path. Do not add Claude-only frontmatter to `SKILL.md`.

- [ ] **Step 2: Add Claude marketplace metadata**

Create `.claude-plugin/marketplace.json` with repository owner `Shereef Bishay`, marketplace name `shereef-skills`, plugin name `shereef-skills`, source `./`, and explicit skill path `./skills/increase-test-coverage`.

- [ ] **Step 3: Add the MIT license**

Use the standard MIT license text with copyright `2026 Shereef Bishay`.

- [ ] **Step 4: Run repository validation**

Run:

```bash
bash scripts/validate.sh
```

Expected: `Validation passed: 1 skill(s)`.

- [ ] **Step 5: Validate host metadata**

Run the existing Codex skill validator against `skills/increase-test-coverage`. Run `claude plugin validate . --strict` when the installed Claude CLI supports it. Record a clear skip rather than claiming success when a host validator is unavailable.

- [ ] **Step 6: Commit the canonical skill**

```bash
git add .claude-plugin LICENSE skills
git commit -m "feat: publish increase-test-coverage skill"
```

### Task 3: Document installation, maintenance, and contribution

**Files:**
- Create: `README.md`
- Create: `docs/adding-a-skill.md`

**Interfaces:**
- Consumes: public repository slug, skill catalog, validation command, Claude marketplace manifest.
- Produces: human installation commands and one copy-paste prompt for an agent on another machine.

- [ ] **Step 1: Write the README**

Document:

- what the collection is and its current skill catalog;
- the primary `npx skills@latest add shereefb/shereef-skills --global --agent claude-code --agent codex --skill '*'` command;
- direct invocation as `/increase-test-coverage` in Claude Code and `$increase-test-coverage` in Codex;
- the optional Claude marketplace commands and a warning not to install both Claude methods;
- update, removal, inspection, and troubleshooting instructions;
- validation and contribution links;
- the approved cross-machine agent prompt with collision checks and verification requirements.

- [ ] **Step 2: Write the future-skill guide**

Document the portable frontmatter contract, canonical directory layout, reference-link rules, marketplace catalog update, README catalog update, local validation, temporary installation test, and commit expectations.

- [ ] **Step 3: Run prose and link checks**

Run:

```bash
rg -n 'TBD|TODO|FIXME|\[TODO' README.md docs skills
bash scripts/validate.sh
git diff --check
```

Expected: the placeholder search finds no unfinished content, validation passes, and `git diff --check` exits `0`.

- [ ] **Step 4: Commit documentation**

```bash
git add README.md docs/adding-a-skill.md
git commit -m "docs: explain cross-agent skill installation"
```

### Task 4: Add continuous validation and test clean installation

**Files:**
- Create: `.github/workflows/validate.yml`
- Modify: `README.md`

**Interfaces:**
- Consumes: `scripts/validate.sh`, the public `skills` CLI, and a temporary empty Git repository.
- Produces: one CI job and evidence that both host targets install from the local repository without touching live global paths.

- [ ] **Step 1: Add GitHub Actions validation**

The workflow runs on pushes and pull requests, checks out the repository, installs current Node.js, runs `bash tests/validate.sh`, runs `bash scripts/validate.sh`, and runs `npx skills@latest add . --list` with telemetry disabled.

- [ ] **Step 2: Test local discovery**

Run:

```bash
DISABLE_TELEMETRY=1 npx skills@latest add . --list
```

Expected: output lists `increase-test-coverage`.

- [ ] **Step 3: Test both agents in an isolated project**

Create a temporary Git repository and run:

```bash
DISABLE_TELEMETRY=1 npx skills@latest add /Users/jarvis/Documents/code/shereef-skills --agent claude-code --agent codex --skill increase-test-coverage --copy --yes
```

Expected: the temporary project receives discoverable Claude Code and Codex skill entries, their `SKILL.md` contents match the canonical source, and no live user directory changes.

- [ ] **Step 4: Run the complete local gate**

Run:

```bash
bash tests/validate.sh
bash scripts/validate.sh
git diff --check
```

Expected: all commands exit `0`.

- [ ] **Step 5: Commit CI**

```bash
git add .github/workflows/validate.yml README.md
git commit -m "ci: validate portable skills"
```

### Task 5: Publish and verify the public GitHub repository

**Files:**
- Modify only if verification exposes a repository defect.

**Interfaces:**
- Consumes: clean local `main`, authenticated GitHub CLI account `shereefb`.
- Produces: public repository `https://github.com/shereefb/shereef-skills` with `main` as its default branch.

- [ ] **Step 1: Verify the local release candidate**

Run:

```bash
git status --short --branch
git log --oneline --decorate -5
bash tests/validate.sh
bash scripts/validate.sh
```

Expected: clean `main`, all validation passing, and the design plus implementation commits present.

- [ ] **Step 2: Create and push the public repository**

Run:

```bash
gh repo create shereef-skills --public --source=. --remote=origin --push --description "Reusable agent skills for Claude Code, Codex, and other Agent Skills-compatible tools"
```

Expected: GitHub returns `https://github.com/shereefb/shereef-skills` and pushes `main`.

- [ ] **Step 3: Verify GitHub state**

Run:

```bash
gh repo view shereefb/shereef-skills --json nameWithOwner,url,visibility,defaultBranchRef
gh api repos/shereefb/shereef-skills/contents/skills/increase-test-coverage/SKILL.md --jq .sha
gh run list --repo shereefb/shereef-skills --limit 5
```

Expected: visibility `PUBLIC`, default branch `main`, the skill file exists, and the validation workflow is queued or completed.

- [ ] **Step 4: Verify a fresh remote clone**

Clone the public URL into a temporary directory, run `bash scripts/validate.sh`, and confirm the cloned head matches local `main`.

- [ ] **Step 5: Report the result**

Return the repository URL, commit SHA, validation evidence, installation command, cross-machine prompt location, and any pending CI state.
