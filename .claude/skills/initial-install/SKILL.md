---
name: initial-install
description: Orchestrates the first-install experience for the portable-ai-ecosystem framework. Walks the operator through 11 states from fresh clone to fully-functional ecosystem parity, delegating to sub-skills (`validate-install`, `initial-setup`, `engagement-bootstrap-from-urls`, `operator-voice-bootstrap`, `wire-hooks-and-tasks`) at specific states. Persists progress to `.claude/_install-state/state.json` so the install is resumable across sessions or device disconnects. Runs a 12-check pre-flight warning matrix before any destructive operation. Idempotent and re-invocable. Use immediately after running `bootstrap.sh` and seeing all `validate-install` probes green; the orchestrator takes over from there.
allowed-tools: Read, Write, Edit, Bash, Glob, Grep
---

# Initial Install

Thin orchestrator that walks the operator from State 4 (entry, post-bootstrap, post-validate) to State 11 (final validation + Initial Install record written). The 11-state machine, the state.json schema, the pre-flight warning matrix, and every recovery procedure live in the playbook at `Universal/FOLLOW-workflows-and-guides/playbooks/initial-install.md`. This skill is the runtime that walks it.

## When this skill fires

The operator just completed, in order:

1. `git clone` of the framework repo
2. `bash Universal/RUN-automations/scripts/bootstrap.sh`
3. `claude` opened in the working folder
4. `/validate-install` returned `INSTALL VALIDATED`

They invoke `/initial-install` to take the install from "the framework is wired" to "the framework is configured and the engagement layer is populated."

Also fires on re-invocation. If `.claude/_install-state/state.json` exists, the skill reads it and resumes from `current_state`.

## What this skill does NOT do

- Does not re-run `bootstrap.sh` (the script is pre-`claude` and the operator owns it)
- Does not duplicate `validate-install` (delegates at State 3 and State 11)
- Does not duplicate `initial-setup` (delegates at State 8)
- Does not duplicate `engagement-bootstrap-from-urls` (delegates at State 10)
- Does not duplicate `operator-voice-bootstrap` (delegates at State 9 when path C runs)
- Does not invoke sub-skills programmatically (prints `/skill-name` for the operator to send; mirrors Claude Code's skill-delegation model)
- Does not auto-install system tools (operator runs install commands in a side terminal)
- Does not request elevated permissions or run `sudo` anywhere

## Steps

### Step 1: Resolve framework root

Resolve `{framework_root}` via `git rev-parse --show-toplevel`. Read `AGENTS.md` to confirm this is the portable-ai-ecosystem repo. If neither succeeds, abort with a one-line "this skill must be invoked from inside the framework repo" message.

### Step 2: Read or initialize state.json

Path: `{framework_root}/.claude/_install-state/state.json`.

Branch:

- **File missing**: first run. Initialize the state object with `current_state: "S4_entry"`, `started_at: now`, `orchestrator_active: true`, all S0-S3 marked completed (the operator already did them), all S4-S11 marked pending. Do not write to disk yet; the write happens after the operator confirms entry at Step 5.
- **File present, parseable**: read `current_state`. Cross-check that the file's `schema_version` matches the playbook's documented version. If schema mismatch, surface a one-line "your state file is from an older install schema; back it up and start over or contact the framework author" and exit.
- **File present, unparseable (corrupted JSON)**: back up to `state.json.bak.{timestamp}`, surface the corruption, ask whether to rebuild from on-disk evidence or start over.

### Step 3: Acquire lock

Path: `{framework_root}/.claude/_install-state/.lock`.

If lock exists with a PID still running, refuse to proceed. If lock exists with a stale PID or is older than 1 hour, warn and reclaim.

Write the lock with `{pid, started_at}`. The lock guards against two parallel `claude` sessions touching state.json (see playbook §"Idempotency model").

### Step 4: Reconcile state vs disk

For every state marked `completed` in state.json, run its post-condition probe (the playbook table lists each post-condition). Examples:

- S1 bootstrap: probe `.claude/_bootstrap-state/bootstrap-completed.txt` exists with today's timestamp
- S3 validated: probe most recent `Universal/RECORD-decisions/*- Install Validation.md` shows `INSTALL VALIDATED`
- S8 setup: probe `.claude/_setup-state/config.json` exists and parses

If a probe fails for a state marked completed, surface "State {N} was marked completed at {timestamp} but its post-condition no longer holds: {detail}. Replay this state or trust the state file and continue?"

This reconciliation pass is the defense against the operator deleting a file, a `git pull` rewriting a config, or other off-band drift.

### Step 5: Run the pre-flight warning matrix (on first State 4 entry)

If this is a fresh install (no state.json existed at Step 2), run the 12-check pre-flight matrix documented in the playbook §"Pre-flight warning matrix". The 12 checks:

1. Terminal emulator (`$TERM_PROGRAM`)
2. Shell (`$SHELL`)
3. OS (`uname`)
4. Locale (`$LANG`)
5. Disk space (`df` under `$HOME`)
6. Claude Code config presence (`~/.config/claude-code/`)
7. Working-folder write probe
8. Network: `github.com` reachable
9. Network: `api.anthropic.com` reachable
10. MDM heuristic (`/Library/Managed Preferences/` populated)
11. Time drift (`date` vs roughly current time; skip if no internet)
12. Bash version (`bash --version`)

For each check, record OK / WARN / FAIL. Print the one-screen pre-flight summary. If any check is FAIL on a critical item (working-folder write, both networks unreachable), halt per the playbook's recovery procedure. If checks are WARN-level, surface the warnings and ask the operator to confirm "continue?".

If state.json existed at Step 2, skip the matrix (already run on first entry).

### Step 6: Print the 11-phase overview at State 4 entry

If `current_state == "S4_entry"` and this is the first invocation in this session, print the State 4 entry message documented in the playbook §"Per-state procedures S4". The message includes: phase table with estimated times, what's optional, the persist-and-resume promise, and a `continue / pause` prompt.

Wait for the operator's reply. On `continue`, write state.json with S4 marked completed and `current_state: "S5_tools"`. On `pause`, write state.json with the current state unchanged and exit cleanly. State.json writes use the atomic-write pattern (Step 12).

### Step 7: Walk States 5 through 11

For each state, in order, execute the loop:

```
while current_state in {S5, S6, S7, S8, S9, S10, S11}:
    1. Print the state's entry message (from the playbook per-state section)
    2. If the state delegates to a sub-skill, print the delegation invocation
    3. Wait for the operator's reply
    4. Verify the state's exit criteria (post-condition probe per playbook table)
    5. If exit criteria met: mark state completed, advance current_state, persist state.json
    6. If exit criteria not met: surface the gap, offer retry / skip / pause
```

The per-state delegation table:

| State | Phase | Delegates to |
|---|---|---|
| S5 | Tool installation | Operator + terminal (no sub-skill in v1.2) |
| S6 | MCP activation (optional) | Operator + terminal (no sub-skill in v1.2) |
| S7 | Hooks and scheduled tasks | `/wire-hooks-and-tasks` |
| S8 | Per-device configuration | `/initial-setup` |
| S9 | Voice customization | `/operator-voice-bootstrap` (only when path C runs) |
| S10 | Engagement bootstrap (optional) | `/engagement-bootstrap-from-urls` |
| S11 | Final validation | `/validate-install` |

### Step 8: Print sub-skill delegation invocations

When a state delegates, do not invoke the sub-skill programmatically. Print:

```
State {N} of 11: {phase name}.

Run /{sub-skill-name} now. When it finishes, reply `done` and I'll
verify the artifact and advance to State {N+1}.
```

After the operator replies `done`, read the sub-skill's `skill_runs[{sub-skill-name}]` block from state.json (the sub-skills participate in state.json as documented in their SKILL.md files). If `outcome == "success"`, advance. If `outcome == "partial"`, surface the partial-summary and ask whether to retry, accept partial, or pause. If `outcome == "failed"` or `outcome == "skipped"`, route to the recovery procedure for that state (see playbook §"Recovery procedures").

### Step 9: Per-state status tracking

Update `states[{state_id}]` in state.json after each transition. Fields per state:

- `name`: phase name (e.g., "tool-installation")
- `status`: one of `pending`, `in_progress`, `completed`, `skipped`, `failed`, `blocked-by-policy`
- `started_at`: ISO 8601 timestamp when the state was entered
- `completed_at`: ISO 8601 timestamp when the state exited (if applicable)
- `artifact`: path to the load-bearing artifact for this state (if applicable)
- `details`: object with state-specific data (per-tool checklist for S5, per-MCP status for S6, per-task status for S7, etc.)

The playbook has the full schema.

### Step 10: Surface recovery procedures on failure

When a state fails (exit criteria not met after retry, or sub-skill returned `failed`), route to the playbook's §"Recovery procedures" section. The playbook documents 9 critical install-broken recovery procedures (P-01 Claude Code not installed, P-02 not authenticated, P-08 working folder occupied, M-01+M-02 Gatekeeper/quarantine, N-01 github.com unreachable, N-04 TLS/MITM, N-06 clone interrupted, PR-01 working folder not writable, V-05 validate-install crashes).

For each failure, print the matching recovery procedure verbatim, write `state.json` with `status: "failed"` and a `blocker` field describing the root cause, release the lock, exit cleanly. The operator runs the recovery action, then re-invokes `/initial-install`; the skill resumes from the failed state.

### Step 11: Complete the install (State 11 exit)

When S11 exits successfully (re-run of `/validate-install` returned green AND the operator confirms `done`):

1. Write the Initial Install record to `Universal/RECORD-decisions/{YYYY-MM-DD} - Initial Install.md`. Body sections: verdict, all 11 phase outcomes, every artifact path, every operator choice, any deferred items (skipped, pending, blocked-by-policy), environment info. Frontmatter:

   ```yaml
   ---
   type: install-record
   last_reviewed: {YYYY-MM-DD}
   sync_trigger: initial-install-{YYYY-MM-DD}
   ---
   ```

2. Append one row to `Universal/RECORD-decisions/_index.md`:

   ```
   | {YYYY-MM-DD} | Initial install completed. {N of 11} phases finalized, {M} skipped (optional). Engagement layer: {bootstrapped for {Company} / deferred}. Voice plan: {status}. | Universal | initial-install skill | [[{YYYY-MM-DD} - Initial Install]] |
   ```

3. Update state.json: `current_state: "DONE"`, S11 marked completed, `completed_at: now`, top-level `status: "complete"`.

4. Print the DONE summary documented in the playbook §"Final report". Surface next-step pointers (`/initiative-kickoff`, `/friction-ledger-capture`, `/self-improvement-review`).

5. Release the lock.

### Step 12: Atomic state.json writes

Every write to state.json uses the temp-and-rename pattern so a partial write never corrupts the file:

```bash
tmp=$(mktemp "{state_file}.XXXXXX")
{updated_json_content} > "$tmp"
mv "$tmp" "{state_file}"
```

On any Ctrl+C or skill abort, the most recent atomic write is the operator's checkpoint. The lock file is removed on clean exit. If the lock survives an abnormal exit, the next invocation handles it per Step 3.

## Resume semantics

When the operator re-invokes `/initial-install`:

1. Read state.json. If `current_state == "DONE"`, print "install already complete (last verified {timestamp}); run `/validate-install` to re-check, `/initial-setup` to revisit per-device config, or `/initial-install replay {N}` to redo a specific phase." Exit.
2. If `current_state != "DONE"`, print "you're at State {N} ({phase name}); last action: {timestamp}. Resume here, replay an earlier phase, or jump forward?"
3. Default: resume at `current_state`.
4. On `replay {N}`: mark state N and all states after as `pending`, set `current_state = "S{N}"`, advance.
5. On `jump forward`: surface a warning that downstream states may fail if upstream prerequisites aren't met. Require explicit operator confirmation.

## Behavior constraints

- Read-only against existing files except state.json, the Initial Install record, the decisions ledger, and `~/Library/LaunchAgents/` (only when State 7 wires plists with operator per-file approval)
- Never auto-remediate. Surface the recovery procedure; operator runs it
- Never invoke sub-skills programmatically; print `/skill-name` and wait for the operator
- Never write secrets to state.json (paths, status codes, version strings only)
- Never modify `Universal/FOLLOW-workflows-and-guides/`, voice files, or playbooks (the operator does that explicitly via `/change-protocol-sweep`)
- On any halt: write state.json, release lock, exit cleanly. No partial filesystem state

## Failure handling

- If state.json write fails (permissions, disk full): surface the error, release the lock if held, abort. State remains at the last successful checkpoint.
- If a sub-skill is missing (e.g., `/wire-hooks-and-tasks` not yet authored at the time of invocation): surface the gap, offer to skip the affected state with `status: "skipped-skill-missing"`, advance.
- If the operator declines to confirm at a state's prompt for over 30 minutes (sentinel "is operator still here?" check): write state.json with `current_state` unchanged and exit cleanly. Next invocation resumes.

## Cross-references

- Spec: `Universal/FOLLOW-workflows-and-guides/playbooks/initial-install.md` (the full state machine, state.json schema, pre-flight matrix, recovery procedures)
- Sub-skills: `validate-install`, `initial-setup`, `engagement-bootstrap-from-urls`, `operator-voice-bootstrap`, `wire-hooks-and-tasks`
- Workflow architecture research: `Universal/PRODUCE-outputs/research/portable-ai-ecosystem-research/initial-install-research/02-workflow-architecture.md`
- Risk and failure modes research: `Universal/PRODUCE-outputs/research/portable-ai-ecosystem-research/initial-install-research/05-risks-and-failure-modes.md`
- Engagement layer activation: `Universal/PRODUCE-outputs/research/portable-ai-ecosystem-research/initial-install-research/04-engagement-layer-activation.md`
- Tool inventory: `Universal/PRODUCE-outputs/research/portable-ai-ecosystem-research/initial-install-research/01-tool-inventory.md`
- Ledger format: `Universal/FOLLOW-workflows-and-guides/playbooks/change-protocol.md` §"Decisions ledger interaction"
