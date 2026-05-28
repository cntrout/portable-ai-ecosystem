---
name: validate-install
description: Validates the portable-ai-ecosystem install by running the 6-probe checklist from portable-ai-ecosystem.md §"Validation". Captures responses, surfaces failures with remediation pointers from the troubleshooting matrix, writes a dated install-record. Use after first clone and bootstrap script execution to confirm the environment is wired correctly. Idempotent, safe to re-run.
allowed-tools: Read, Write, Bash, Glob
---

# Validate Install

Runtime for the 6-probe validation checklist defined in `Universal/FOLLOW-workflows-and-guides/playbooks/portable-ai-ecosystem.md` §"Validation". The checklist confirms voice composition rule loads, initiatives enumerate, folder-creation rules cite correctly, push prevention works, git pull behavior is right, and voice self-attest fires inside an initiative.

## When this skill fires

The user invokes after first install, after a `git pull`, or any time they suspect drift in the local environment.

## Steps

### Step 1: Load the checklist spec

Read `Universal/FOLLOW-workflows-and-guides/playbooks/portable-ai-ecosystem.md` and locate §"Validation". Extract the 6-probe table (probe number, prompt, expected response shape).

### Step 2: Run each probe

For each row, in order:

1. State the probe number and what it tests
2. Show the user the exact prompt to send (or, if running in the same `claude` session, simulate by inspecting the relevant config files)
3. Capture the response verbatim
4. Compare against the expected response shape
5. Mark PASS, FAIL, or AMBIGUOUS with a one-sentence rationale

For AMBIGUOUS results, ask the user: "Probe N returned X, expected Y. Treat as PASS, FAIL, or retry?"

**Probe 6 (voice self-attest inside an initiative) special case:** This probe requires an initiative to exist. On a first install (no initiatives yet), no initiative directory exists to test inside. Before running probe 6, check whether any directory exists under `Initiatives/` other than `_template/`. If none exists:

- Mark probe 6 as **PASS (skipped, no initiatives created yet)**
- Add a one-line note in the install-record: "Probe 6 deferred. Re-run validate-install after the first initiative is created via `initiative-kickoff` to confirm Layer 3 voice composition fires inside an initiative directory."
- Do not treat the skip as a FAIL or AMBIGUOUS.

This is the expected graceful path on a first install. The skill can be re-invoked later (idempotent) to validate probe 6 once an initiative exists.

### Step 3: Aggregate

Tally PASS / FAIL / AMBIGUOUS counts. Verdict:

- All 6 PASS → INSTALL VALIDATED
- Any unresolved FAIL → INSTALL HAS GAPS, list which probes failed
- Any unresolved AMBIGUOUS → INCONCLUSIVE

### Step 4: Surface remediation for failures

For each FAIL, look up the matching row in `INSTALL.md` §"8. Troubleshooting". Surface the remediation steps to the user. Offer to retry the probe after they remediate.

### Step 5: Write the install-record

Write to `Universal/RECORD-decisions/{YYYY-MM-DD} - Install Validation.md`:

```yaml
---
type: install-record
last_reviewed: {YYYY-MM-DD}
sync_trigger: install-validation-{YYYY-MM-DD}
---
```

Body sections:
- **Verdict** (one of INSTALL VALIDATED / INSTALL HAS GAPS / INCONCLUSIVE)
- **Per-probe results** with prompt, response excerpt, and PASS/FAIL/AMBIGUOUS for each
- **Failed probes and remediation** if any
- **Environment info** (Claude Code version from `claude --version`, working directory, OS version)
- **Next steps**

### Step 6: Append a ledger row

In `Universal/RECORD-decisions/_index.md`, add:

```
| {YYYY-MM-DD} | Install validation: {verdict}. {N of 6} probes passed. {remediation summary if any}. | Universal | validate-install skill | [[{YYYY-MM-DD} - Install Validation]] |
```

## State-file participation

The `initial-install` orchestrator skill writes `.claude/_install-state/state.json` to track install progress across resumable sessions. When `validate-install` runs (whether the operator invokes it directly OR the orchestrator delegates to it), it participates in that state file as a co-operative writer. The orchestrator owns the file; this skill writes only its own per-skill block.

Stand-alone invocation is still fully supported. If `.claude/_install-state/state.json` does not exist, the skill behaves exactly as documented above (writes the install-record, appends the ledger row, prints next steps to the operator). No state-tracking; the skill is unchanged.

### When state.json exists

1. **Read state.json at start.** Path: `{framework_root}/.claude/_install-state/state.json` (where `{framework_root}` is the output of `git rev-parse --show-toplevel`). Parse it. If the file has `orchestrator_active: true`, record locally that this skill is running as part of an orchestrated install.

2. **Suppress next-step prompts when orchestrator is active.** Normally after Step 5 and Step 6 the skill points the operator at next steps. When `orchestrator_active: true`, skip those prompts; the orchestrator owns the operator-facing next-step messaging. The skill still writes the install-record and the ledger row as usual.

3. **Use the lock file convention.** Before writing to state.json, check for `{framework_root}/.claude/_install-state/.lock`. If the lock exists and its modification time is fresher than 5 minutes, wait briefly and re-check, or abort the state write and surface to the operator. The install-record and ledger row still write regardless of the lock; only the state.json update is gated. Full lock semantics (PID, stale-cleanup) are owned by the orchestrator.

4. **Write the per-skill block on completion.** Update `state.json` with a `skill_runs["validate-install"]` block:

   ```json
   {
     "last_run_at": "2026-MM-DDTHH:MM:SS",
     "outcome": "success",
     "summary": "all 6 probes passed",
     "invoked_by": "orchestrator"
   }
   ```

   Outcome values:
   - `success`: all 6 probes PASS (probe 6 skipped graciously on no-initiative also counts as success)
   - `partial`: some probes PASS, some AMBIGUOUS marked as such
   - `failed`: one or more probes FAIL after remediation offered
   - `skipped`: the operator aborted before all probes ran

   The `invoked_by` value is `orchestrator` if `orchestrator_active: true` was read at start; otherwise `operator`.

5. **Atomic write.** Use the `mktemp` + `mv` pattern so a partial write never corrupts state.json:

   ```bash
   tmp=$(mktemp "$STATE_FILE.XXXXXX")
   {updated_json} > "$tmp"
   mv "$tmp" "$STATE_FILE"
   ```

### state.json contract

The full contract (owned by the orchestrator):

```json
{
  "version": "1.0",
  "schema_version": 1,
  "orchestrator_active": true,
  "current_state": "S3_validated",
  "started_at": "2026-MM-DDTHH:MM:SS",
  "last_updated_at": "2026-MM-DDTHH:MM:SS",
  "completed_states": ["S0_clone", "S1_bootstrap", "S2_session", "S3_validated"],
  "skill_runs": {
    "validate-install": {
      "last_run_at": "2026-MM-DDTHH:MM:SS",
      "outcome": "success",
      "summary": "all 6 probes passed",
      "invoked_by": "orchestrator"
    },
    "initial-setup": { },
    "engagement-bootstrap-from-urls": { }
  }
}
```

`validate-install` only writes its own `skill_runs["validate-install"]` block plus a refresh of `last_updated_at`. It never modifies `current_state`, `completed_states`, or other skills' blocks. Those are the orchestrator's.

## Behavior constraints

- Read-only against the user's existing files except the install-record and the ledger
- Never auto-remediate. Only surface remediation steps; the user runs them
- If skill invocation happens in a partially-installed environment (missing AGENTS.md, broken paths), report the gap and exit cleanly without writing a partial record

## Cross-references

- Spec: `Universal/FOLLOW-workflows-and-guides/playbooks/portable-ai-ecosystem.md` §"Validation"
- Troubleshooting matrix: `INSTALL.md` §"8. Troubleshooting"
- Ledger format: `Universal/FOLLOW-workflows-and-guides/playbooks/change-protocol.md` §"Decisions ledger interaction"
