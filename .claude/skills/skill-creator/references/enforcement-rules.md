# Enforcement Rules: full detail

Loaded by SKILL.md when a rule needs to be explained, justified, or applied with nuance. Each rule below has: **what**, **why**, **how to detect**, **action on violation**.

---

## 1. Preflight checks before any work

### 1.1 pwd partition alignment

**What:** When authoring an initiative-scoped skill, the user's pwd at invocation time should be inside that initiative's folder, or the scope should be explicitly declared at a higher level.

**Why:** Skills inherit the partition of the initiative they are authored in. Authoring a skill scoped to `initiative:foo` from inside `Initiatives/bar/` produces a cross-initiative breadcrumb.

**How to detect:** Compare `pwd` to declared `partition-scope` frontmatter. Mismatch is a violation.

**Action:** WARN. Surface the partition rule, ask the user to confirm scope or change pwd before proceeding.

### 1.2 AGENTS.md ↔ CLAUDE.md byte-identity

**What:** Repo-root and any initiative-level AGENTS.md / CLAUDE.md pairs must be byte-identical at the start of any skill authoring work.

**Why:** Drift means one file is stale. Authoring on a stale baseline produces inconsistent skills.

**How to detect:**
```bash
REPO_ROOT=$(git rev-parse --show-toplevel)
cmp "$REPO_ROOT/AGENTS.md" "$REPO_ROOT/CLAUDE.md"
# plus per-initiative for relevant ones
```

**Action:** BLOCK. Show `diff` output. Tell the user which file is newer by mtime. Refuse to proceed until resolved.

---

## 2. Naming, location, and structure conventions

### 2.1 Naming

- kebab-case
- Lowercase alphanumerics plus hyphens only
- 40 characters or fewer
- No `-skill` suffix (it is already a skill folder, that is redundant)
- Unique within `.claude/skills/`

### 2.2 Structure

```
.claude/skills/{name}/
├── SKILL.md (required, ideally under 500 lines)
├── README.md (optional)
├── CHANGELOG.md (optional, recommended once a skill has had multiple releases)
├── eval-baseline.json (optional, written after first eval)
├── .last-used (counter file, append-only)
├── scripts/ (optional, executable code)
├── references/ (optional, large docs loaded on demand)
├── templates/ (optional, files used as skeletons)
├── assets/ (optional, files used in output)
└── evals/
    └── evals.json (optional, test cases for self-eval)
```

### 2.3 Required frontmatter fields

| Field | Type | Required | Notes |
|---|---|---|---|
| `name` | string | yes | kebab-case identifier matching folder name |
| `description` | string | yes | trigger phrases plus what and when. Be explicit; Claude under-triggers. |
| `allowed-tools` | array | yes | strict subset of what the skill actually uses |

### 2.4 Optional frontmatter fields

| Field | Type | Notes |
|---|---|---|
| `version` | semver | starts at `1.0.0` if used |
| `partition-scope` | enum | `universal`, `initiative:{slug}` |
| `lifecycle-state` | enum | `draft`, `ready`, `deprecated`, `retired` |
| `argument-hint` | string | for slash invocation hint |
| `compatibility` | object | upstream-style compat declaration if relevant |

---

## 3. Trigger-phrase discipline

### 3.1 Explicit triggers required

Every description must include literal phrasings ("create a skill", "improve [skill]") AND anti-triggers ("not for X").

### 3.2 Be explicit about firing conditions

Claude under-triggers skills. Descriptions should explicitly say "use this skill whenever..." not just describe the skill's function.

### 3.3 Cross-skill conflict detection

Before scaffolding, grep existing `.claude/skills/_index.md` and installed plugins for trigger overlap. On overlap: WARN, suggest extending the existing skill, allow override with `--bypass`.

---

## 4. Soft-partition enforcement

### 4.1 Initiative-scoped skills

- Declare `partition-scope: initiative:{slug}` in frontmatter
- May assert pwd at runtime if strict isolation matters:
  ```bash
  if [[ "$PWD" != *"Initiatives/{slug}"* ]]; then
    echo "ERROR: This skill expects pwd inside Initiatives/{slug}/"
    exit 1
  fi
  ```
- Examples in the skill text must NOT reference other initiatives' data, even hypothetically

### 4.2 Universal skills

- Declare `partition-scope: universal`
- May read across all of `Initiatives/*/` and any framework-shared paths
- Must NEVER write to a specific initiative folder without explicit pwd context from the user's invocation
- Must NEVER infer cross-initiative conclusions without explicit user direction

### 4.3 Cross-initiative reads under soft partition

The framework uses soft partition: initiatives can read each other by default. No special declaration needed for a skill that reads across initiative folders. A skill declared `partition-scope: universal` can read anywhere; a skill declared `partition-scope: initiative:{slug}` is scoped to its own initiative for writes but may read sibling initiatives if the work warrants it. Document cross-initiative read patterns in the skill body when they matter.

---

## 5. Atomic AGENTS.md / CLAUDE.md protection

### 5.1 No direct edits

No skill may use Edit or Write on:

- Repo-root `AGENTS.md`
- Repo-root `CLAUDE.md`
- Any `Initiatives/*/AGENTS.md`
- Any `Initiatives/*/CLAUDE.md`

This applies to any optimizer that might be tempted to edit context files. The skill-creator polices this.

### 5.2 Doc suggestions go to a local outbox

When a skill needs a doc change (for example, a new tool added that warrants a registry entry):

- Write a markdown diff suggestion to `Universal/PRODUCE-outputs/machine-generated/skill-creator/YYYY-MM-DD-doc-suggestion-{skill-name}.md`
- Format: target file + current section + proposed change + rationale
- Human reviews and applies manually, preserving the atomic byte-identity rule

The `Universal/PRODUCE-outputs/machine-generated/skill-creator/` folder is git-ignored by default. Create it if it does not exist.

---

## 6. Memory architecture compatibility

### 6.1 No alternative memory systems

Skills MUST NOT create:

- Parallel SQLite databases
- Separate vector stores
- Custom embedding pipelines
- Alternative caching layers in user-level config directories

If the framework has a canonical memory layer, use it. If not, store outputs as standard markdown so any indexer can pick them up.

### 6.2 Output paths for indexed content

Outputs that should be indexed go to standard markdown paths under the repo, not to hidden cache folders.

---

## 7. Counter-file pattern for retired-skill detection

### 7.1 Why this exists

Skill invocation telemetry at the platform layer is unreliable across hosts. The counter-file pattern is a self-report mechanism: every skill writes a timestamp to its own `.last-used` file on every invocation.

### 7.2 Implementation

The skill-creator template (`templates/skill-md-skeleton.md`) bakes a "Self-report invocation" step into every new skill. The step calls `scripts/write-last-used.sh` with the skill's own path.

### 7.3 Rotation

The `write-last-used.sh` script keeps the last 1000 entries by default. That is roughly three years of history at one use per day, which is enough for retired-skill detection.

### 7.4 Retired-skill detection

A health-check pass can read every `.last-used` file across `.claude/skills/` and flag skills with no entries in 180 or more days as retired candidates. Manual review before deletion.

---

## 8. Evaluation discipline

### 8.1 Eval baseline (optional but recommended)

After a Create or Eval run, `.claude/skills/{name}/eval-baseline.json` should exist if the operator wants regression tracking. The skill-creator writes it from the grader's output.

Schema:
```json
{
  "skill_name": "string",
  "created": "ISO-8601 with offset",
  "last_evaluated": "ISO-8601 with offset",
  "version_at_eval": "semver",
  "trigger_precision": 0.0,
  "trigger_recall": 0.0,
  "grading": { }
}
```

The load-bearing field names (`text`, `passed`, `evidence`) are preserved verbatim inside `grading` so any standard viewer can render the file.

### 8.2 No "ready" state without baseline (if using lifecycle states)

If a skill uses `lifecycle-state` frontmatter, the skill-creator refuses to mark a skill `ready` (move out of `draft`) without an eval baseline.

### 8.3 Regression detection

A health-check pass can re-run evals on a cadence, compare to baseline, and flag regression, improvement, or staleness.

---

## 9. Lifecycle states (optional)

In skill frontmatter, optional `lifecycle-state` field:

| State | Meaning | Transition |
|---|---|---|
| `draft` | scaffolded, no eval baseline yet | → `ready` after baseline established |
| `ready` | default state, evaled, in production | → `deprecated` when superseded |
| `deprecated` | obsolete, replacement named in `replaced-by` field, retained but hidden from triggers | → `retired` after 180 days unused |
| `retired` | deletion candidate flagged by the retired-skill detection pass | manual review required for deletion |

Transitions only via the skill-creator.

---

## 10. Cross-skill awareness

Before scaffolding, the skill-creator:

1. Reads `.claude/skills/_index.md` (if present)
2. Searches for trigger-phrase overlap (substring plus fuzzy match)
3. Searches for description semantic overlap if a semantic search MCP is available
4. If overlap is significant, WARN and suggest extending the existing skill

User can override with `--bypass <reason>`.

---

## 11. Documentation auto-generation (suggest, never apply)

The skill-creator auto-updates:

- `.claude/skills/_index.md` (atomic in-place edit, this file is skill-creator-owned)

The skill-creator writes SUGGESTIONS for human review:

- `Universal/FOLLOW-workflows-and-guides/playbooks/` (or the framework's playbook path): when a skill encodes a recurring process
- Framework tools registry: when a skill introduces a new external tool or dependency
- AGENTS.md / CLAUDE.md: when an ecosystem-level convention emerges (rare, surfaces in outbox with high visibility)

Suggestions land at `Universal/PRODUCE-outputs/machine-generated/skill-creator/YYYY-MM-DD-doc-suggestion-{skill-name}.md` with format:

```markdown
# Doc suggestion for {skill-name}

**Target file:** {path}
**Section:** {heading}
**Reason:** {why this update matters}

## Proposed change

```diff
- old content
+ new content
```

**Rationale:** {2 or 3 sentences}
```

---

## 12. Anti-patterns

See `anti-patterns.md` for the full list with rationale and severity.
