---
bloat_check: skip
bloat_check_reason: Folder-purpose README. Not a daily artifact.
---

# Universal/PRODUCE-outputs/handoffs/

**Purpose:** Cross-conversation handoff briefs for universal work. When a session is about to end and the next session needs to pick up where this one left off, write the handoff here so the next operator (or the next Claude session) can resume without re-deriving context.

## What lives here

Handoffs that touch shared infrastructure, framework-level work, or any deliverable that crosses initiative boundaries. Examples that belong here:

- Skill development handoffs (a skill being scoped, built, or refined)
- Voice or exemplar authoring handoffs
- Workspace infrastructure handoffs (folder restructure, automation cadence changes)
- Cross-initiative work that lives at the engagement level

## What does not live here

- Initiative-scoped handoffs belong in `Initiatives/{slug}/PRODUCE-outputs/handoffs/`. If the handoff only matters for one initiative and would not make sense to someone working on a different one, it goes there instead.
- Machine-generated automation reports belong in `Universal/PRODUCE-outputs/machine-generated/automation-reports/` if that folder exists on this install. Those are scheduled-task outputs, not session handoffs.

When in doubt, ask: "Would this brief make sense for someone working on a different initiative?" If yes, it goes here. If no, it goes in the initiative.

## Lifecycle

Accreting. Once written, kept indefinitely as a historical artifact. A handoff that became obsolete (the work shipped, was abandoned, or got superseded by a newer handoff) stays here rather than getting deleted. The shipped or abandoned state is its own value; future sessions can see what was decided and why.

Pass 1 staleness is not enforced on this folder. Treat handoffs like a personal journal of cross-session work: dated, append-only, never trimmed mechanically.

## Naming convention

`YYYY-MM-DD - {Descriptive Title}.md` per the vault-wide dated convention. One file per work package; do not split a single handoff across multiple files.

Optional frontmatter for searchability:

```yaml
status: in-flight | shipped | abandoned | superseded
```

Add `bloat_check: skip` to handoff docs over ~400 lines (intentional long-form briefings should be exempt from bloat audits).

## Cross-references

- `Universal/FOLLOW-workflows-and-guides/playbooks/change-protocol.md`: handoffs that document a system-file change reference the protocol from this file.
- `Initiatives/{slug}/PRODUCE-outputs/handoffs/README.md`: the initiative-scoped equivalent.
