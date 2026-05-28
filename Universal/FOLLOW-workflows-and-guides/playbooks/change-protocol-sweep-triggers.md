---
type: playbook
last_reviewed: null
---

# Change-Protocol Sweep Triggers

Reference for when the `change-protocol-sweep` skill should be invoked. The edit-time sync rules in `AGENTS.md` cover what to keep in sync; this file covers when the sweep itself gets prompted, since v1.2 has no nightly health-check backstop to catch missed invocations.

The skill itself lives at `Universal/RUN-automations/skills/change-protocol-sweep/SKILL.md`. The full protocol lives at `Universal/FOLLOW-workflows-and-guides/playbooks/change-protocol.md`. This file is the trigger surface: the prompts and moments that should remind the operator (or the session) to run a sweep.

## Why this exists

Today the operator runs the sweep manually after a system-file edit. Without a nightly health-check backstop, a missed sweep stays missed until the next time someone touches an affected file. This file catalogs the moments the operator (or Claude in-session) should pause and consider running the sweep.

In v1.3, the `workspace-health-check` skill will catch missed sweeps in observation mode (Pass 19 equivalent) and auto-graduate to active mode after a calibration window. Until then, this file is the discipline aid.

## Trigger moments

Run the sweep after any of the following edits, before the session ends:

### System-file edits

- Any edit to `AGENTS.md` or `CLAUDE.md` (the two are byte-identical siblings; an edit to one always implies the other).
- Any edit under `Universal/FOLLOW-workflows-and-guides/playbooks/`.
- Any edit under `Universal/FOLLOW-workflows-and-guides/voice/`.
- Any edit to `Universal/RUN-automations/skills/{skill-slug}/SKILL.md` or its dependencies.
- Any edit to `Universal/RUN-automations/skills/_index.md`.

### Structural changes

- Folder creation or deletion under `Universal/`, `Initiatives/`, or at the workspace root.
- A new entry in `Universal/RECORD-decisions/_index.md` that codifies a rule the rest of the framework should reflect.
- A rename or move of any file that other docs reference by path.

### External triggers

- After an `external-tool-approval.md` decision lands (a new tool, MCP, or plugin gets approved or rejected).
- After a sanitization-scan finds matches that produce file edits.
- After an initiative kickoff or close.

## How the trigger surfaces in practice

Three places the trigger should appear:

1. **Session start.** The session-start hook can include a line in its output that reminds the operator: "If you edited system files last session, run change-protocol-sweep before continuing." The hook does not auto-detect; it just nudges.

2. **In-session, after a system-file edit.** Claude in the active session should propose the sweep when it sees an edit to a system-file path. The proposal is not automatic; the operator decides whether to run it now, batch with later edits, or defer.

3. **Natural conversation endings.** When a session is wrapping up and Claude detects a batched edit set that has not been flushed, propose the sweep before the operator closes the session.

## What the sweep covers

The full six-step procedure lives in `change-protocol.md`. The condensed version:

1. Identify affected files (cross-reference search).
2. Update each affected file.
3. Verify referential integrity.
4. Mirror AGENTS↔CLAUDE if either changed.
5. Run a concept-search pass for related content the operator should know about.
6. Append a row to `Universal/RECORD-decisions/_index.md` if the change codifies a decision.

## Operator discipline until v1.3

Until `workspace-health-check` ships, the sweep is operator-discipline-only. The triggers above are the discipline aid. The framework does not enforce them; the operator decides each time.

The v1.3 health-check will move some of this load off the operator: Pass 19 will detect drift between system files and surface it nightly. This file stays useful even after v1.3 lands as the in-session trigger reference.

## Cross-references

- `Universal/FOLLOW-workflows-and-guides/playbooks/change-protocol.md`: the full protocol the sweep follows.
- `Universal/RUN-automations/skills/change-protocol-sweep/SKILL.md`: the skill the trigger invokes.
- `AGENTS.md`: the edit-time sync rules that define what gets kept in sync.
- `Universal/RECORD-decisions/_index.md`: the ledger the sweep writes to.

---

*One-shot reference until v1.3 ships the nightly backstop. Updated when new trigger moments are identified during real use.*
