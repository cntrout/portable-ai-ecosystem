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

## Behavior constraints

- Read-only against the user's existing files except the install-record and the ledger
- Never auto-remediate. Only surface remediation steps; the user runs them
- If skill invocation happens in a partially-installed environment (missing AGENTS.md, broken paths), report the gap and exit cleanly without writing a partial record

## Cross-references

- Spec: `Universal/FOLLOW-workflows-and-guides/playbooks/portable-ai-ecosystem.md` §"Validation"
- Troubleshooting matrix: `INSTALL.md` §"8. Troubleshooting"
- Ledger format: `Universal/FOLLOW-workflows-and-guides/playbooks/change-protocol.md` §"Decisions ledger interaction"
