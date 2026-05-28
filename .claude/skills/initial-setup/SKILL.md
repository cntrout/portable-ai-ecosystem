---
name: initial-setup
description: Configures per-device choices after first install. Walks the operator through friction-ledger location, self-improvement-review cadence, voice customization plan, and any other per-device settings the framework's skills depend on. Invoke once after `bootstrap.sh` completes and before doing real work; the skill is idempotent and re-invocable so the operator can revisit any decision later. Writes setup state to `.claude/_setup-state/config.json` and a row to the decisions ledger so the choices are recoverable and auditable.
allowed-tools: Read, Write, Edit, Bash, Glob, Grep
---

# Initial Setup

Per-device configuration runtime. Sits alongside `validate-install` in the post-bootstrap sequence: `validate-install` checks the install is correct; `initial-setup` configures choices the operator needs to make.

## When this skill fires

The operator just completed:
1. `bash Universal/RUN-automations/scripts/bootstrap.sh`
2. `validate-install` skill (all probes green)

And is about to do real work. This skill is also re-invocable any time the operator wants to revisit configuration (change ledger path, change cadence, regenerate voice files, etc.).

## What this skill does NOT do

- Does not validate install (`validate-install` does that)
- Does not populate engagement content (`engagement-bootstrap-from-urls` does that)
- Does not create initiatives (`initiative-kickoff` does that)
- Does not modify system files in `Universal/FOLLOW-workflows-and-guides/` or root AGENTS.md / CLAUDE.md (the operator does that explicitly via the change-protocol sweep)

This skill ONLY writes to `.claude/_setup-state/config.json` and appends one row to `Universal/RECORD-decisions/_index.md`.

## Steps

### Step 1: Read existing config (if any)

Check whether `.claude/_setup-state/config.json` already exists. If yes, read it and show the operator the current configuration. Tell them they're in "revisit mode"; defaults pulled from existing config. If no, this is first-run; defaults pulled from the framework's recommendations.

### Step 2: Confirm framework root

Auto-detect via `git rev-parse --show-toplevel`. Show the path to the operator and confirm it's the intended working folder. If git isn't available or this isn't a repo yet, fall back to `pwd` and ask the operator to confirm.

Record the resolved path in `config.framework_root` (absolute path).

### Step 3: Friction-ledger location

Two skills depend on this path: `friction-ledger-capture` (writes to it) and `self-improvement-review` (reads from it).

Default: `Universal/PRODUCE-outputs/friction-ledger.md` (relative to framework root).

Ask the operator:
- Accept the default?
- Or choose a different relative path (e.g., `Universal/RECORD-decisions/friction-ledger.md`)?

If the operator picks a non-default path, surface a warning: any later skill expecting the default will need to read the config.json for the override.

Record in `config.friction_ledger.path`.

If the ledger file doesn't exist yet at the chosen path, create it with the template header (header + empty `## Entries` section + sentinel HTML comment for the next-entry append point).

### Step 4: Self-improvement-review cadence

The `self-improvement-review` skill reads the friction ledger periodically and proposes framework improvements. The operator picks the cadence.

Defaults:
- Cadence: `weekly`
- Day of week: `friday`

Other options to surface:
- `daily` (high signal, high noise)
- `weekly` with different day
- `biweekly`
- `monthly` (low maintenance)
- `manual-only` (operator invokes; no scheduled reminder)

Record in `config.self_improvement_review.{cadence, day_of_week}`.

If the operator picks anything other than `manual-only`, surface the v2 path: "Once `launchd` user agents are approved and authored, this cadence will drive a scheduled invocation. For v1, you invoke the skill manually on this cadence."

### Step 5: Voice customization plan

The framework ships with the framework author's voice as the worked example (`personal.md`). For the operator's own work, three paths:

1. **Use as-shipped**: emails will sign "Best, Corey Trout" and use the author's vocabulary. Acceptable if the operator is using the framework purely as a learning tool or scaffold and isn't generating customer-facing copy yet.
2. **Customize now**: the operator regenerates `personal.md` from their own writing samples (sent emails, Slack history, blog posts). This skill doesn't do the regeneration; it surfaces the procedure and writes a TODO marker.
3. **Customize later**: acknowledge the voice mismatch and commit to regenerating before the first customer-facing deliverable.

Ask the operator which path. Record in `config.voice.personal_md_status` as one of: `framework-author-default`, `operator-customized`, `operator-pending`.

If `operator-pending`, surface the regeneration procedure (collect 100+ writing samples, summarize voice patterns, write to `Universal/FOLLOW-workflows-and-guides/voice/personal.md`, run `change-protocol-sweep` if voice rules changed).

### Step 6: Workspace-health-check posture (v1.2 placeholder)

The `workspace-health-check` skill is not in v1.1; it ships in v1.2. This step is a placeholder so the operator can express intent now.

Ask: "When `workspace-health-check` ships, do you want it enabled by default? (y/n; default y)"

Record in `config.workspace_health_check.enabled_when_available`.

### Step 7: Write config.json

Write the consolidated config to `.claude/_setup-state/config.json`. Format example:

```json
{
  "version": "1.0",
  "setup_completed_at": "2026-05-28T14:32:00",
  "framework_root": "/Users/{operator}/path/to/repo",
  "friction_ledger": {
    "path": "Universal/PRODUCE-outputs/friction-ledger.md"
  },
  "self_improvement_review": {
    "cadence": "weekly",
    "day_of_week": "friday"
  },
  "voice": {
    "personal_md_status": "operator-pending"
  },
  "workspace_health_check": {
    "enabled_when_available": true
  }
}
```

Create `.claude/_setup-state/` directory if it doesn't exist. The folder is in the repo's root `.gitignore` (per `bootstrap.sh` setup) so config.json stays local and never commits.

### Step 8: Append ledger row

Append one row to `Universal/RECORD-decisions/_index.md`:

```
| {YYYY-MM-DD} | Initial setup completed. Friction ledger at {path}. Review cadence: {cadence} on {day}. Voice plan: {status}. WHC-when-available: {y/n}. | Universal | initial-setup skill | (rationale: per-device configuration captured at first install or revisit) |
```

This row is the audit trail for "what did the operator configure and when."

### Step 9: Confirm and print next steps

Report a summary of what was configured. Surface the next-step pointers:

- "Configuration complete. Start your first engagement with `engagement-bootstrap-from-urls`."
- "Or create your first initiative with `initiative-kickoff`."
- "Run `friction-ledger-capture` at end of day to populate the ledger."
- "Run `self-improvement-review` on your chosen cadence."

## Behavior constraints

- Never write to anything outside `.claude/_setup-state/`, the friction-ledger file (only to create the template if missing), and `Universal/RECORD-decisions/_index.md`
- Never modify voice files, playbooks, AGENTS/CLAUDE, hooks, or any other system file
- Always surface the existing config in revisit mode before prompting for new values
- Always require explicit operator confirmation on framework_root before writing config

## Failure handling

- If `git rev-parse` fails and `pwd` doesn't look like the framework root: surface to the operator, ask them to navigate to the framework root and re-invoke
- If write to `.claude/_setup-state/config.json` fails (permissions, disk full): surface and abort cleanly; nothing partial gets written
- If `Universal/RECORD-decisions/_index.md` doesn't exist: surface as a setup gap (it should have shipped); abort
- If the operator declines to make a choice at any step: skip with a `null` value and a TODO marker in config.json

## Re-invocation

Safe to re-run any time. The skill detects existing config, shows it to the operator, and offers per-key revision. Only the keys the operator changes get updated. New ledger row gets appended on each successful re-run with the diff summary.

## Cross-references

- `validate-install` skill: runs before this one to confirm the environment is correct
- `friction-ledger-capture` skill: depends on `config.friction_ledger.path`
- `self-improvement-review` skill: depends on `config.friction_ledger.path` and `config.self_improvement_review.cadence`
- `bootstrap.sh` script: runs before this skill; creates `.claude/_setup-state/` directory at install time
- Decisions ledger: `Universal/RECORD-decisions/_index.md`
