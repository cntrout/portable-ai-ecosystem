---
name: skill-creator
description: Author, evaluate, improve, or benchmark any Claude skill inside the portable-ai-ecosystem framework. Adds framework conventions on top of skill authoring: soft-partition enforcement (initiative-scoped vs universal), atomic AGENTS.md/CLAUDE.md byte-identity protection, custom frontmatter preservation across improve cycles, retired-skill detection via per-skill `.last-used` counters, anti-pattern rejection (no writes to system context files, no overlapping triggers, no missing trigger phrases), and benchmark-mode cost warnings. Use this skill whenever creating a new skill, improving an existing one, running evals, benchmarking versions, or optimizing a skill's description for better triggering. Triggers on "create a skill", "make a new skill", "improve [skill]", "eval [skill]", "benchmark [skill]", "optimize [skill] description", "author a skill for X", "build me a skill that does Y", or any reference to authoring or modifying anything under `.claude/skills/`. Do NOT trigger on reading existing skills for reference, normal skill use, or asking what skills exist.
allowed-tools: Read, Write, Edit, Bash, Glob, Grep
---

# Skill Creator

The framework-aware authoring layer for Claude skills inside the portable-ai-ecosystem repo. Every new or modified skill under `.claude/skills/` should pass through this skill.

This skill applies a policy and convention layer on top of standard skill authoring. The structural value it adds:

- Soft-partition enforcement so initiative-scoped skills do not leak into other initiatives
- The atomic AGENTS.md ↔ CLAUDE.md byte-identity rule (any skill that touches either file is rejected)
- Custom frontmatter field preservation across improve cycles (a description optimizer can strip fields it does not recognize)
- A `.last-used` counter file pattern for retired-skill detection (broken upstream skill telemetry workaround)
- Cost warnings before benchmark mode (multi-iteration parallel evals get expensive fast)
- Anti-pattern rejection with a quarantine path so broken drafts do not pollute the skills directory

## When this skill fires

Trigger on any of these classes of request:

- **Create**: "make a skill for X", "I need a skill that does Y", "build me a skill", "create a new skill"
- **Improve**: "improve [skill]", "make [skill] better", "fix [skill]", "[skill] is broken"
- **Eval**: "eval [skill]", "test [skill]", "score [skill]", "run [skill] against test cases"
- **Benchmark**: "benchmark [skill]", "compare versions of [skill]", "A/B test [skill]"
- **Description optimize**: "optimize [skill]'s description", "[skill] is not triggering", "fix triggering for [skill]"
- Any direct touch of `.claude/skills/` (creating folders, editing SKILL.md files)

## When NOT to fire

- Reading existing skills for reference without modification
- Using a skill (just running it normally)
- Asking what skills exist
- Editing skill-adjacent files (READMEs, playbooks) that are not SKILL.md itself

## The four modes

Determine which mode the user wants from their intent:

1. **Create**: scaffold a new skill from scratch
2. **Improve**: edit an existing skill based on user feedback or new requirements
3. **Eval**: run a skill against test prompts and grade results
4. **Benchmark**: compare two versions (A/B blind comparison)

Mode dispatch is conversational. If ambiguous, ask once.

## Workflow

### Step 1: Resolve the repo root

All paths in this skill resolve relative to the repo root. Resolve it once at the top of the workflow:

```bash
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
```

If `git rev-parse` fails (not a git repo), fall back to the current working directory and warn the user.

### Step 2: Preflight checks (blocks on critical failures)

Run preflight before anything else. Exit codes:

- `0`: all checks passed, proceed
- `1`: blocking failure (partition violation or AGENTS.md/CLAUDE.md byte-identity drift), STOP and surface the error
- `2`: warnings issued, proceed but include warnings in chat output

| Check | Severity | Action on fail |
|---|---|---|
| Repo-root AGENTS.md ↔ CLAUDE.md byte-identical | BLOCK | refuse + show diff |
| Any `Initiatives/{slug}/AGENTS.md` ↔ `CLAUDE.md` byte-identical | BLOCK | refuse + show diff |
| pwd inside an initiative folder when authoring an initiative-scoped skill | WARN | confirm partition scope with user |
| Skill name kebab-case and unique within `.claude/skills/` | BLOCK on collision, WARN on naming nit | suggest alternative |
| Trigger phrases overlap with existing skill | WARN | flag overlap, allow override with `--bypass` |

The `--bypass` flag must include a one-line rationale that gets logged to `Universal/PRODUCE-outputs/machine-generated/skill-creator/skill-authoring-bypass-log.md` with timestamp, skill name, and reason. The log appends, never overwrites. Create `Universal/PRODUCE-outputs/machine-generated/skill-creator/` if it does not exist; the folder is git-ignored by default.

The preflight checks live in `scripts/preflight.sh` (see Reference files). If the script is not present (early framework state), inline the checks: read both files, compare bytes, surface diff on mismatch.

### Step 3: Mode-specific work

After preflight, run the chosen mode. The framework applies these rules during all modes:

#### Live constraints (apply to every mode)

- **No edits to repo-root `AGENTS.md` or `CLAUDE.md`** by any skill being authored. If a doc update would help, write a suggestion to `Universal/PRODUCE-outputs/machine-generated/skill-creator/YYYY-MM-DD-doc-suggestion-{skill-name}.md` instead. The atomic byte-identity rule is non-negotiable.
- **No edits to initiative-level `Initiatives/{slug}/AGENTS.md` or `CLAUDE.md`** for the same reason.
- **No skill may read or write across the initiative partition.** A skill declared `partition-scope: initiative:foo` cannot read from `Initiatives/bar/`.
- **No skill may write to framework-managed hidden folders** (`.git/`, `.claude/` config itself, any tool-owned cache directory).

#### Benchmark-mode cost warning

Before running benchmark mode, ALWAYS warn the user:

> Benchmark mode runs multi-iteration evals with parallel subagents. On larger models this typically costs around $1 per run plus token usage from your account budget. For N test cases × 2 configurations × 3 runs, expect roughly $1-3 plus around 150K tokens. Proceed?

Wait for explicit confirmation. If the user proceeds, log the run start to `Universal/PRODUCE-outputs/machine-generated/skill-creator/benchmark-runs-log.md` with timestamp, skill name, and estimated scope.

#### Custom frontmatter preservation (Improve mode specifically)

Improve mode rewrites SKILL.md. A description optimizer can strip custom frontmatter fields the framework relies on (for example, `partition-scope`, `lifecycle-state`, or any field the operator added).

Pattern:

1. **Before delegating to Improve**: snapshot the existing frontmatter to a temporary JSON file:
   ```bash
   python3 scripts/inject-custom-frontmatter.py --snapshot <skill-path>
   ```
2. **After Improve returns**: re-inject the snapshot:
   ```bash
   python3 scripts/inject-custom-frontmatter.py --restore <skill-path>
   ```
3. **Verify** by reading the new SKILL.md and confirming the custom fields are present.

Never accept an Improve cycle whose post-state lacks the original custom frontmatter. The principle holds regardless of which specific fields the operator uses: snapshot before, restore after, verify after restore.

### Step 4: Post-process (runs on success)

After mode work completes:

1. **Validate frontmatter**: required fields present (`name`, `description`, `allowed-tools`). Optional fields the framework recognizes: `version` (semver), `partition-scope`, `lifecycle-state`, `argument-hint`. If a required field is missing, prompt the user rather than auto-filling.

2. **Write or update `eval-baseline.json`** (for Create or Eval runs): capture the grader's output as `.claude/skills/{name}/eval-baseline.json`. Mirror the standard grading shape with load-bearing fields (`text`, `passed`, `evidence`):
   ```json
   {
     "skill_name": "...",
     "created": "YYYY-MM-DDTHH:MM:SS-04:00",
     "last_evaluated": "YYYY-MM-DDTHH:MM:SS-04:00",
     "version_at_eval": "1.0.0",
     "trigger_precision": 0.0,
     "trigger_recall": 0.0,
     "grading": { }
   }
   ```

3. **Counter-file pattern**: ensure `.claude/skills/{name}/.last-used` exists. Every skill INVOCATION (different from authoring) appends a timestamp:
   ```
   YYYY-MM-DDTHH:MM:SS-04:00
   ```
   to its `.last-used` file. The framework template (see `templates/skill-md-skeleton.md`) bakes this in. This is how retired-skill detection works without relying on platform-level telemetry.

4. **Update `.claude/skills/_index.md`** (if present): read it, add or modify the row for this skill, write back. Atomic. Never auto-add entries to AGENTS.md or CLAUDE.md.

5. **Emit doc suggestions** to `Universal/PRODUCE-outputs/machine-generated/skill-creator/` if the skill introduces:
   - A new external tool or MCP dependency (suggests adding to the tools registry, if the framework has one)
   - A recurring process worth a playbook entry
   - A new convention worth documenting

   Suggestions land at `Universal/PRODUCE-outputs/machine-generated/skill-creator/YYYY-MM-DD-doc-suggestion-{skill-name}.md` for human review. Never auto-apply.

6. **Quarantine on rejection**: if anti-pattern checks fail (see Anti-patterns below), move the work-in-progress to `.claude/skills/.drafts/{name}/` and surface the rejection reason. Do NOT leave broken skills in `.claude/skills/`.

### Step 5: Test runs and eval workflow (Create, Eval, Benchmark only)

The eval workflow:

- Spawn parallel subagents where the host supports them
- One with-skill run plus one baseline run per test case
- Save outputs to `Universal/PRODUCE-outputs/machine-generated/skill-creator/_evals/{skill-name}/iteration-N/` (NOT inside `.claude/skills/`, so eval artifacts do not ship with the skill itself)
- Grade each run, producing a `grading.json` per run
- Aggregate across runs
- Generate a static review viewer if the host provides one
- Surface results to the user for review
- Iterate based on user feedback

## Anti-patterns the skill rejects

Reject and quarantine to `.claude/skills/.drafts/{name}/` (full rationale per item in `references/anti-patterns.md`):

| ID | Pattern | Severity |
|---|---|---|
| A1 | Writes to repo-root or initiative AGENTS.md / CLAUDE.md | BLOCK |
| A2 | Writes to framework-managed hidden folders (`.git/`, tool caches) | BLOCK |
| A3 | No trigger phrases in description | BLOCK |
| A4 | No exit or skip conditions documented | WARN |
| A5 | Overlapping unresolved triggers with an existing skill | WARN |
| A6 | Skill body references hardcoded `~/` paths instead of resolving relative to repo root | WARN |
| A7 | Examples or templates bake in personal or client-specific data | WARN (BLOCK if obviously a leak) |
| A8 | `allowed-tools` exceeds what the skill actually uses | WARN |
| A9 | `version` field present but missing semver or set to `0.0.0` | WARN |
| A10 | Single-MCP-call wrapper (use the MCP directly) | WARN |
| A11 | Auto-edits framework docs without writing to `Universal/PRODUCE-outputs/machine-generated/skill-creator/` first | BLOCK |

Rejected skills go to `.claude/skills/.drafts/{name}/` for iteration, not silent discard.

## Communicating with the operator

Skill authoring is a high-investment workflow. Be explicit at decision points:

- Before starting work, confirm the mode you have inferred ("Looks like you want to Create a new skill named X, confirm or adjust")
- Before benchmark mode, surface the cost warning verbatim
- After preflight warnings, list them and ask whether to bypass or fix
- After mode work returns, confirm what was written, what was post-processed, and any outbox suggestions emitted
- Default to short chat replies unless reporting structured results

## Reference files

- `references/anti-patterns.md`: full anti-pattern list with detection logic and suggested alternatives
- `references/enforcement-rules.md`: each framework rule expanded with what, why, how to detect, and action on violation
- `templates/skill-md-skeleton.md`: house skeleton for new SKILL.md files
- `templates/eval-baseline.json`: initial baseline schema for new skills
- `scripts/preflight.sh`: preflight checks (bash, standalone, no external dependencies)
- `scripts/inject-custom-frontmatter.py`: snapshot and restore custom frontmatter across improve cycles
- `scripts/write-last-used.sh`: append timestamp to a skill's `.last-used` counter file

## Versioning the meta-skill

The skill-creator itself uses semver. Major bumps when the enforcement contract changes (new blocking rules). Minor when new rules are added that are warn-only. Patch for clarifications, doc fixes, script bug fixes.

Periodic review: evaluate whether new framework patterns warrant new rules.
