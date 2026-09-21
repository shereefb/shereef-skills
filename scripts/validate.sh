#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
repo_root="${1:-$(cd "$script_dir/.." && pwd -P)}"
errors=0

fail() {
  printf 'ERROR: %s\n' "$*" >&2
  errors=1
}

if ! command -v ruby >/dev/null 2>&1; then
  printf 'ERROR: ruby is required to validate YAML and JSON\n' >&2
  exit 1
fi

skills_root="$repo_root/skills"
marketplace="$repo_root/.claude-plugin/marketplace.json"

if [[ ! -d "$skills_root" ]]; then
  fail "missing skills directory: $skills_root"
fi

if [[ ! -f "$marketplace" ]]; then
  fail "missing Claude marketplace manifest: $marketplace"
fi

shopt -s nullglob
skill_dirs=("$skills_root"/*)
skill_count=0

if [[ ${#skill_dirs[@]} -eq 0 ]]; then
  fail "no skills found under $skills_root"
fi

read_frontmatter_field() {
  ruby -ryaml -e '
    text = File.read(ARGV[0])
    parts = text.split(/^---[[:space:]]*$\n?/, 3)
    abort "missing YAML frontmatter" unless parts.length == 3 && parts[0].strip.empty?
    data = YAML.safe_load(parts[1], aliases: false)
    abort "frontmatter must be a mapping" unless data.is_a?(Hash)
    allowed = %w[name description license compatibility metadata allowed-tools]
    unknown = data.keys.map(&:to_s) - allowed
    abort "unsupported portable frontmatter: #{unknown.join(", ")}" unless unknown.empty?
    value = data[ARGV[1]]
    puts value if value
  ' "$1" "$2"
}

for skill_dir in "${skill_dirs[@]}"; do
  [[ -d "$skill_dir" ]] || continue
  skill_count=$((skill_count + 1))
  skill_name="$(basename "$skill_dir")"
  skill_file="$skill_dir/SKILL.md"

  if [[ ! -f "$skill_file" ]]; then
    fail "missing SKILL.md: $skill_dir"
    continue
  fi

  if ! declared_name="$(read_frontmatter_field "$skill_file" name 2>&1)"; then
    fail "$skill_file has invalid frontmatter: $declared_name"
    continue
  fi

  if ! description="$(read_frontmatter_field "$skill_file" description 2>&1)"; then
    fail "$skill_file has invalid frontmatter: $description"
    continue
  fi

  if [[ -z "$declared_name" ]]; then
    fail "$skill_file is missing frontmatter name"
  elif [[ "$declared_name" != "$skill_name" ]]; then
    fail "$skill_file name '$declared_name' does not match directory '$skill_name'"
  fi

  if [[ -z "$description" ]]; then
    fail "$skill_file is missing frontmatter description"
  fi

  while IFS= read -r reference; do
    [[ -n "$reference" ]] || continue
    case "$reference" in
      http://*|https://*|mailto:*|\#*|/*)
        continue
        ;;
    esac

    reference="${reference%%#*}"
    reference="${reference%%::*}"
    if [[ ! -e "$skill_dir/$reference" ]]; then
      fail "$skill_file has broken local reference: $reference"
    fi
  done < <(ruby -e 'File.read(ARGV[0]).scan(/\]\(([^)]+)\)/).flatten.each { |link| puts link }' "$skill_file")

  codex_metadata="$skill_dir/agents/openai.yaml"
  if [[ -f "$codex_metadata" ]]; then
    if ! ruby -ryaml -e 'data = YAML.safe_load(File.read(ARGV[0]), aliases: false); abort "root must be a mapping" unless data.is_a?(Hash)' "$codex_metadata" >/dev/null 2>&1; then
      fail "$codex_metadata contains invalid YAML"
    fi
  fi
done

marketplace_skills=()
if [[ -f "$marketplace" ]]; then
  if ! ruby -rjson -e 'data = JSON.parse(File.read(ARGV[0])); abort "plugins must be an array" unless data["plugins"].is_a?(Array)' "$marketplace" >/dev/null 2>&1; then
    fail "$marketplace contains invalid marketplace JSON"
  else
    while IFS= read -r skill_path; do
      [[ -n "$skill_path" ]] || continue
      marketplace_skills+=("$skill_path")
      normalized_path="${skill_path#./}"
      if [[ ! -d "$repo_root/$normalized_path" ]]; then
        fail "$marketplace lists missing skill path: $skill_path"
      fi
    done < <(ruby -rjson -e 'data = JSON.parse(File.read(ARGV[0])); data.fetch("plugins", []).flat_map { |plugin| plugin.fetch("skills", []) }.each { |path| puts path }' "$marketplace")
  fi
fi

for skill_dir in "${skill_dirs[@]}"; do
  [[ -d "$skill_dir" ]] || continue
  expected_path="./skills/$(basename "$skill_dir")"
  listed=0
  for marketplace_skill in "${marketplace_skills[@]}"; do
    if [[ "$marketplace_skill" == "$expected_path" ]]; then
      listed=1
      break
    fi
  done
  if [[ $listed -eq 0 ]]; then
    fail "$expected_path is not listed in marketplace.json"
  fi
done

published_paths=("$skills_root")
[[ -f "$repo_root/README.md" ]] && published_paths+=("$repo_root/README.md")
[[ -f "$repo_root/docs/adding-a-skill.md" ]] && published_paths+=("$repo_root/docs/adding-a-skill.md")

if grep -R -n -E '\[(TODO|FIXME)\]|<(TODO|FIXME)>|REPLACE_ME|Add the task-specific guidance' "${published_paths[@]}" >/dev/null 2>&1; then
  fail "published files contain an unfinished placeholder"
fi

if [[ $errors -ne 0 ]]; then
  exit 1
fi

printf 'Validation passed: %d skill(s)\n' "$skill_count"
