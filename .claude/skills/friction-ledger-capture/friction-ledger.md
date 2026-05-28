---
type: log
created: YYYY-MM-DD
last_processed_session: none
---

# Friction Ledger

Append-only capture log for the self-improvement loop (Phase 1). Written by the `friction-ledger-capture` skill; read by the `self-improvement-review` skill on a longer cadence.

## What goes here

Each entry is a single **generalized behavioral observation**: a place where Claude's behavior diverged from what the operator wanted, stated with no project names, client facts, deliverable contents, or other specifics.

Entry format:

```
### YYYY-MM-DD: <short behavioral headline>

- **Signal:** explicit-feedback | violated-rule | correction | re-explanation
- **Observation:** <what Claude did, and what the operator wanted instead, generalized>
- **Implicated artifact:** <CLAUDE.md / a named SKILL.md / a playbook / unclear>
- **Evidence:** <a short generalized paraphrase of the moment, not a verbatim quote>
```

## Partition note

This ledger is operator-agnostic by construction. The capture skill records only generalized behavior and never transcribes project names, numbers, deliverable contents, or other project-specific detail. If a friction moment cannot be stated without specifics, it is not recorded.

## Processing watermark

`last_processed_session` in the frontmatter is the most recent session the capture skill has already processed. Each run processes idle, top-level sessions more recent than that marker, then advances it. The watermark advances on every run, including runs that capture no entries, so the next run doesn't reprocess the same sessions.

On the first run, `last_processed_session: none` tells the skill to process only the single most recent idle top-level session rather than backfilling history.

---

## Entries

<!-- New entries are appended below this line, most recent at the bottom. -->
