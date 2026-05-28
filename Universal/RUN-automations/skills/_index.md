---
type: registry
last_reviewed: null
---

# Skills Registry

Inventory of skills installed on this instance of the framework. Each row points to a `SKILL.md` under `Universal/RUN-automations/skills/{skill-slug}/`. The registry is the lookup the `change-protocol-sweep` skill reads when it needs to identify which skills are affected by a system-file edit.

Skills are unit workflows: definitions of what work gets done. Scheduling (when a skill runs on a cadence) lives separately in `Universal/RUN-automations/scheduled-tasks/` and is reflected in `Universal/FOLLOW-workflows-and-guides/playbooks/automation-schedule.md`.

## Skills shipped in this distribution

| Skill | What it does |
|---|---|
| `initial-install` | First-install orchestrator; walks the operator through 11 states with resumable `.claude/_install-state/state.json` progress tracking; delegates to the sub-skills below at specific phases |
| `validate-install` | Six-probe install verification; writes an install record on success |
| `initial-setup` | Per-device configuration (friction-ledger path, capture cadence and time, review cadence and time, voice plan, health-check posture) |
| `engagement-bootstrap-from-urls` | Orchestrates parallel research agents to populate the engagement layer (voice Layer 3, glossary, brand assets, thesis) from public URLs |
| `operator-voice-bootstrap` | Regenerates `personal.md` (Layer 2 baseline voice) from the operator's own writing samples; mirrors engagement-bootstrap-from-urls but for Layer 2 |
| `wire-hooks-and-tasks` | Generates and loads macOS launchd user agents from cadence preferences in `.claude/_setup-state/config.json`; idempotent and re-runnable after `initial-setup` |
| `sanitization-scan` | Twenty-five-pattern ripgrep scan with per-file disposition for past-engagement scrubbing |
| `initiative-kickoff` | Creates `Initiatives/{slug}/` with the verb-bucket skeleton |
| `change-protocol-sweep` | Automates the six-step doc-sync ripple sweep on system-file edits |
| `friction-ledger-capture` | Phase 1 of the self-improvement loop; append-only friction capture |
| `self-improvement-review` | Phase 2 of the self-improvement loop; propose-only system-file improvements |
| `skill-creator` | Authoring wrapper for new skills; enforces anti-patterns and runs eval baselines |
| `process-meeting-transcripts` | Source-agnostic transcript ingestion, classification, and filing |

## How to add a row

When a new skill is authored under `Universal/RUN-automations/skills/{slug}/`, append a row to the table above in the same change. The skill's own `SKILL.md` is the source of truth for behavior; this registry is the lookup.

Per the edit-time sync rules in `AGENTS.md`, a skill addition also requires:

- A `CHANGELOG.md` inside the skill folder (created in the same change).
- A row in `Universal/RECORD-decisions/_index.md` if the new skill is non-trivial.

## Slash commands

If this instance defines any operator-invoked slash commands at `.claude/commands/`, list them here so the registry stays a single lookup. Slash commands are not skills (no `SKILL.md`) but live in the same conceptual surface.

| Command | What it does |
|---|---|

## Third-party skills installed at the surface level

Skills installed via Claude Desktop, Cowork, or a plugin browser do not live in this folder. Listed here for visibility only when the operator installs them.

| Skill | Source |
|---|---|

## Cross-references

- `Universal/FOLLOW-workflows-and-guides/playbooks/change-protocol.md`: the protocol that reads this registry during ripple sweeps.
- `Universal/RUN-automations/scheduled-tasks/README.md`: cadence wiring for the subset of skills that run on a schedule.
- `Universal/FOLLOW-workflows-and-guides/playbooks/automation-schedule.md`: the operator's chosen cadences and their rationale.

---

*Append-only growth. Rows for deprecated skills get a "deprecated" note rather than getting deleted, so historical references still resolve.*
