---
name: <kebab-case-name>
description: <one or two sentences describing what the skill does AND when to use it. Include literal trigger phrases users would type. Be explicit, say "use this skill whenever..." to combat under-triggering. Also include an explicit "Do NOT trigger on..." anti-list to combat over-triggering.>
allowed-tools: <strict subset of tools this skill actually uses, for example Read, Write, Bash>
---

# <Skill Name>

<One-paragraph description of what the skill does and why it exists.>

## When to use

<3 to 5 bullet points listing concrete situations when this skill should fire. These should overlap with the trigger phrases in the description but can be more nuanced.>

## When NOT to use

<3 or more explicit anti-cases. This combats over-triggering.>

## Inputs

<What does the skill expect from the user? URL, file path, free text, structured args?>

## Outputs

<What does the skill produce? File paths, chat output, side effects on the repo?>

## Workflow

### Step 1: <name>

<imperative instructions>

### Step 2: <name>

<imperative instructions>

### Step N: Self-report invocation

ALWAYS run at the end of every invocation to enable retired-skill detection:

```bash
SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
bash "${SKILL_DIR}/../skill-creator/scripts/write-last-used.sh" "${SKILL_DIR}"
```

The path traverses one level up then down into `skill-creator/scripts/`. If skill-creator is not present in the same `.claude/skills/` tree, either hardcode an alternative path or skip this step and accept that retired-skill detection will not see usage for this skill.

## Reference files

- `references/<topic>.md`: <when to load this>

## Partition Rationale (only required if the skill writes across initiative boundaries)

<If the skill needs to write into a specific initiative folder other than the active one, document why and what guardrails apply. Under soft partition, reading across initiatives is the default and needs no rationale.>

## Changelog

See CHANGELOG.md if the skill tracks versions.

---

## Authoring notes (delete this section before shipping)

- Filed by skill-creator. Any custom frontmatter fields you add (for example, `partition-scope`, `lifecycle-state`) MUST be preserved across Improve cycles. The skill-creator handles this automatically via `scripts/inject-custom-frontmatter.py`.
- Update CHANGELOG.md on every release if the skill tracks versions.
- See `references/enforcement-rules.md` in the skill-creator folder for the full rule set.
