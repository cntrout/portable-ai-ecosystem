---
type: ledger
bloat_check: skip
bloat_check_reason: Append-only decision ledger.
---

# Decisions Ledger

Append-only record of foundational decisions made on this instance of the framework. One row per decision. The `change-protocol` sweep writes here; the format spec is in `Universal/FOLLOW-workflows-and-guides/playbooks/change-protocol.md` under "Decisions ledger interaction."

This file is bloat-check exempt; annual rotation moves rows older than ~12 months into `_archive/{year}.md`.

## Ledger

| Date | Decision | Scope | Triggered by | Record |
|------|----------|-------|--------------|--------|

## Row format

When the change-protocol sweep completes, append one row with this shape:

- **Date**: `YYYY-MM-DD` of the decision, not the doc edit
- **Decision**: one-sentence statement of what was locked, written so it stands alone outside the ledger
- **Scope**: `Universal` for ecosystem-wide; the initiative slug for initiative-scoped (the initiative-scoped row lives in `Initiatives/{slug}/RECORD-decisions/_index.md` instead)
- **Triggered by**: the originating action (a research doc, a handoff, a session, an incident, an external trigger)
- **Record**: wikilink to the detail doc if rationale is non-obvious; blank for mechanical changes (skill version bumps, typo fixes in rule files)

If a decision is dense enough to deserve its own ADR-style file, save it at `Universal/RECORD-decisions/YYYY-MM-DD - {slug}.md` and link it in the Record column alongside (or instead of) the research-doc link.

## Related

- `Universal/FOLLOW-workflows-and-guides/playbooks/change-protocol.md`: the protocol that writes here

*History: this file is the history record.*
