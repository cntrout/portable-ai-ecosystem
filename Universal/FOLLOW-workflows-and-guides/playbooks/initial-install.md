---
type: playbook
last_reviewed: 2026-05-28
sync_trigger: 2026-05-28-v1.2-skills-batch
depends-on:
  - playbook:portable-ai-ecosystem
  - playbook:engagement-bootstrap-from-urls
  - playbook:change-protocol
  - playbook:folder-creation-rules
---

# Initial Install Playbook

Spec for the `initial-install` skill. Walks the operator from "I have a fresh clone of the portable-ai-ecosystem framework, bootstrap.sh ran, validate-install is green" all the way to "the framework is configured, the engagement layer is populated, and the install is final-validated."

The skill is the runtime. This playbook is the canonical reference: the state machine, the state.json schema, the pre-flight warning matrix, the per-state procedures, the recovery procedures, the idempotency model. An operator who prefers manual control can walk this playbook as a checklist; the skill is the assisted path.

Companion playbooks: `portable-ai-ecosystem.md` (the framework overview), `engagement-bootstrap-from-urls.md` (Track B engagement layer), `change-protocol.md` (when a system file changes, what ripples).

## When to run

The operator just completed, in order:

1. `git clone` of the framework repo into a working folder
2. `bash Universal/RUN-automations/scripts/bootstrap.sh` (or `./bootstrap.sh` if executable)
3. `claude` opened in the working folder; the session-start hook fired and loaded `Universal/AGENTS.md` into context
4. `/validate-install` returned `INSTALL VALIDATED` (5 or 6 probes green; probe 6 graceful-skip is fine on first install)

They invoke `/initial-install` to take the install from "the framework is wired" to "the framework is configured and ready to do real work."

Also fires on re-invocation. If `.claude/_install-state/state.json` exists, the skill reads it and resumes from `current_state`.

## Outcome

When `/initial-install` exits with `current_state: "DONE"`:

- `.claude/_install-state/state.json` records all 11 phase outcomes
- `.claude/_setup-state/config.json` is written (friction-ledger path, review cadence, voice plan)
- `Universal/RECORD-decisions/{YYYY-MM-DD} - Initial Install.md` is the audit record
- `Universal/RECORD-decisions/_index.md` has a row for the install
- Engagement layer is either populated (`/engagement-bootstrap-from-urls` ran) or explicitly deferred
- Voice customization is either complete (`/operator-voice-bootstrap` ran) or explicitly deferred
- Required scheduled tasks are either wired and verified (`/wire-hooks-and-tasks` ran) or explicitly skipped
- The framework is ready for `/initiative-kickoff`

## Inputs

| Required | Optional |
|---|---|
| The operator. | Public URLs for the client engagement (for `/engagement-bootstrap-from-urls` at State 10). |
| `bootstrap.sh` completion marker. | Operator writing samples for `/operator-voice-bootstrap` (at State 9 path C). |
| A green `validate-install` install-record. | Client name / slug. |
| Network reachability to `github.com` and `api.anthropic.com`. | A side terminal for tool installs at State 5. |

## State machine

The install is a directed graph of 12 states (S0 through S11). S0-S3 are external prerequisites the operator completes before invoking `/initial-install`. The orchestrator owns S4 through S11. The DONE state is the terminal node.

```
S0 fresh-clone
    |
    v
S1 bootstrap-completed
    |
    v
S2 claude-open
    |
    v
S3 validate-install-passes
    |
    v
S4 initial-install-entry  <-- orchestrator starts here
    |
    v
S5 tool-installation
    |
    v
S6 mcp-activation (optional)
    |
    v
S7 hooks-and-tasks
    |
    v
S8 per-device-config
    |
    v
S9 voice-customization
    |
    v
S10 engagement-bootstrap (optional)
    |
    v
S11 final-validation
    |
    v
DONE
```

### State-by-state table

| State | Phase | Pre-condition | Post-condition | Delegated skill |
|---|---|---|---|---|
| S0 | fresh-clone | Operator has `git`, `claude` on PATH, Claude Code authenticated. | Working folder contains the framework tree (`AGENTS.md`, `CLAUDE.md`, `.claude/`, `Universal/`, `Initiatives/`). | None. |
| S1 | bootstrap-completed | S0 complete. | `.claude/_bootstrap-state/bootstrap-completed.txt` exists with today's timestamp; `Initiatives/.gitignore` exists; `settings.local.json` exists; `pull.ff = only` set. | `bootstrap.sh`. |
| S2 | claude-open | S1 complete. | `claude` is running in the working folder; session-start hook loaded `Universal/AGENTS.md`. | None. |
| S3 | validate-install-passes | S2 complete. | A new `Universal/RECORD-decisions/{date} - Install Validation.md` exists with verdict `INSTALL VALIDATED`. | `/validate-install`. |
| S4 | initial-install-entry | S3 complete. | state.json initialized; pre-flight matrix run; operator confirmed `continue`. | None (orchestrator). |
| S5 | tool-installation | S4 complete. | Required-floor tools all `completed`; recommended tools either `completed` or operator confirmed `skip`. | Operator + side terminal. |
| S6 | mcp-activation | S5 complete. | Operator's selected MCPs configured in `claude_desktop_config.json` or equivalent, OR phase skipped. | Operator + side terminal. |
| S7 | hooks-and-tasks | S6 complete or skipped. | Operator's selected launchd agents loaded via `launchctl load`, OR phase skipped. | `/wire-hooks-and-tasks`. |
| S8 | per-device-config | S7 complete or skipped. | `.claude/_setup-state/config.json` exists; ledger row appended. | `/initial-setup`. |
| S9 | voice-customization | S8 complete. | `personal.md` status matches `config.voice.personal_md_status`; if path C ran, `personal.md` is regenerated and `change-protocol-sweep` rippled any voice-rule changes. | `/operator-voice-bootstrap` (only on path C). |
| S10 | engagement-bootstrap | S9 complete or skipped. | Engagement-layer paths populated (`voice.md`, `glossary.md`, `thesis.md`, `people.md`, `_overview.md`), OR phase skipped. | `/engagement-bootstrap-from-urls`. |
| S11 | final-validation | S10 complete or skipped. | New `Install Validation.md` written; verdict captured. Initial Install record written. Ledger row appended. | `/validate-install`. |
| DONE | terminal | S11 complete. | state.json `current_state: "DONE"`; DONE summary printed. | None. |

## state.json schema

The orchestrator owns the file. Sub-skills write only their own `skill_runs[{skill-name}]` block. The orchestrator owns `current_state`, `completed_states`, and the top-level metadata.

Path: `{framework_root}/.claude/_install-state/state.json`.

```json
{
  "version": "1.0",
  "schema_version": 1,
  "orchestrator_active": true,
  "started_at": "2026-05-28T14:00:00",
  "last_updated_at": "2026-05-28T15:42:11",
  "current_state": "S7_hooks",
  "completed_states": ["S0_clone", "S1_bootstrap", "S2_claude_open", "S3_validated", "S4_entry", "S5_tools", "S6_mcp"],
  "status": "in-progress",
  "operator_identity_hint": "username via $(whoami)",
  "claude_code_version": "2.1.144",
  "working_folder": "/Users/{operator}/path/to/repo",
  "states": {
    "S0_clone": {
      "name": "fresh-clone",
      "status": "completed",
      "completed_at": "2026-05-28T09:14:22"
    },
    "S1_bootstrap": {
      "name": "bootstrap-completed",
      "status": "completed",
      "completed_at": "2026-05-28T09:18:05",
      "artifact": ".claude/_bootstrap-state/bootstrap-completed.txt"
    },
    "S2_claude_open": {
      "name": "claude-open",
      "status": "completed",
      "completed_at": "2026-05-28T09:18:40"
    },
    "S3_validated": {
      "name": "validate-install-passes",
      "status": "completed",
      "completed_at": "2026-05-28T09:22:11",
      "artifact": "Universal/RECORD-decisions/2026-05-28 - Install Validation.md"
    },
    "S4_entry": {
      "name": "initial-install-entry",
      "status": "completed",
      "completed_at": "2026-05-28T14:00:30",
      "preflight": {
        "terminal": "OK",
        "shell": "OK",
        "os": "OK",
        "locale": "OK",
        "disk_free": "OK",
        "claude_config": "OK",
        "workdir_write": "OK",
        "network_github": "OK",
        "network_anthropic": "OK",
        "mdm_indicator": "WARN",
        "time_drift": "OK",
        "bash_version": "OK"
      }
    },
    "S5_tools": {
      "name": "tool-installation",
      "status": "completed",
      "completed_at": "2026-05-28T14:32:00",
      "details": {
        "checklist": {
          "git": "completed",
          "claude": "completed",
          "curl": "completed",
          "homebrew": "completed",
          "ripgrep": "completed",
          "jq": "completed",
          "node": "completed",
          "obsidian": "skipped",
          "drive-desktop": "skipped"
        }
      }
    },
    "S6_mcp": {
      "name": "mcp-activation",
      "status": "completed",
      "completed_at": "2026-05-28T14:48:00",
      "details": {
        "checklist": {
          "smart-connections": "completed",
          "session-info": "skipped",
          "scheduled-tasks": "skipped"
        }
      }
    },
    "S7_hooks": {
      "name": "hooks-and-tasks",
      "status": "in_progress",
      "started_at": "2026-05-28T15:42:11"
    },
    "S8_setup": { "name": "per-device-config", "status": "pending" },
    "S9_voice": { "name": "voice-customization", "status": "pending" },
    "S10_engagement": { "name": "engagement-bootstrap", "status": "pending" },
    "S11_final": { "name": "final-validation", "status": "pending" }
  },
  "skill_runs": {
    "validate-install": {
      "last_run_at": "2026-05-28T09:22:11",
      "outcome": "success",
      "summary": "5 of 6 probes passed; probe 6 deferred (no initiatives yet)",
      "invoked_by": "operator"
    },
    "initial-setup": {},
    "engagement-bootstrap-from-urls": {},
    "operator-voice-bootstrap": {},
    "wire-hooks-and-tasks": {}
  },
  "warnings": [
    { "step": "preflight", "message": "MDM indicators present; recovery procedures may be needed" }
  ],
  "errors": []
}
```

### Field documentation

- `version`: state.json file format version, distinct from `schema_version`.
- `schema_version`: integer used to detect breaking changes in the schema. Bumped when the orchestrator's state graph changes shape.
- `orchestrator_active`: true while the orchestrator is walking the install; sub-skills read this to know whether to write their per-skill block.
- `started_at`: ISO 8601 timestamp of the first invocation.
- `last_updated_at`: refreshed on every state transition.
- `current_state`: the state the orchestrator is currently in. Set to `"DONE"` when the install completes.
- `completed_states`: ordered list of state IDs that have exited successfully.
- `status`: one of `in-progress`, `complete`, `paused-prereq`, `paused-network`, `paused-mdm`, `error`.
- `operator_identity_hint`: `$(whoami)` output. Used for the DONE summary's "installed by" line. Never an email or full name.
- `claude_code_version`: `claude --version` output captured at S4 entry.
- `working_folder`: absolute path to the framework root.
- `states`: per-state object. Each state has `name`, `status`, and optionally `started_at`, `completed_at`, `artifact`, `details`, `notes`. State status values: `pending`, `in_progress`, `completed`, `skipped`, `failed`, `blocked-by-policy`, `skipped-skill-missing`.
- `skill_runs`: per-sub-skill block. Each sub-skill writes its own block per its SKILL.md state-file-participation section.
- `warnings`: non-fatal issues surfaced during install. One object per warning.
- `errors`: fatal issues that halted the install. One object per error.

### Forbidden contents

The state file is gitignored but still local-disk-readable. Do not write:

- API keys, OAuth tokens, or any credentials
- Personally-identifying info beyond `$(whoami)`
- File contents (paths only)
- URL lists from engagement bootstrap (those go to the engagement-bootstrap-from-urls staging files)
- Operator writing samples

## Pre-flight warning matrix

Run on first State 4 entry. 12 checks, one screen of output, decision point at the bottom.

| # | Check | What it detects | Action on hit |
|---|---|---|---|
| 1 | Terminal emulator | `$TERM_PROGRAM` is iTerm2 / Terminal.app / other | WARN if exotic; the skill's prompts may render oddly. |
| 2 | Shell | `$SHELL` is zsh / bash / fish | WARN if fish; inline commands assume bash; skill uses `bash -c` internally. |
| 3 | OS | macOS / Linux / other | WARN if other; the skill is tested on macOS and major Linux distros. |
| 4 | Locale | `$LANG` is UTF-8 | WARN if not UTF-8; non-UTF-8 locales may cause render issues. |
| 5 | Disk space | `df` shows > 500 MB free under `$HOME` | WARN if under 500 MB; the framework needs roughly 50 MB plus engagement state. |
| 6 | Claude Code config | `~/.config/claude-code/` exists | Inform only; the skill never modifies this directory. |
| 7 | Working-folder write probe | `touch {framework_root}/.write-test && rm` succeeds | FAIL if write denied; halt with recovery procedure PR-01. |
| 8 | Network: github.com | `curl -sS -o /dev/null -w "%{http_code}" -m 10 https://github.com/` returns 200/301/302 | FAIL if unreachable; halt with recovery procedure N-01. |
| 9 | Network: api.anthropic.com | Same probe to api.anthropic.com | FAIL if unreachable; halt with recovery procedure N-01. |
| 10 | MDM indicator | `/Library/Managed Preferences/` populated (macOS) | WARN if present; surface "have INSTALL.md §3 IT-ticket template ready." |
| 11 | Time drift | `date` output vs roughly current time | WARN if more than 5 minutes off; TLS cert checks can fail. |
| 12 | Bash version | `bash --version` returns 3.0+ | WARN if older; macOS ships 3.2 by default. |

The pre-flight surface:

```
=== initial-install pre-flight checks ===

Environment:
  Terminal: Terminal.app (OK)
  Shell: zsh (OK)
  OS: macOS 14.5 (OK)
  Locale: en_US.UTF-8 (OK)
  Disk free: 12.3 GB under /Users/{operator} (OK)
  Claude Code config: /Users/{operator}/.config/claude-code/ (OK)

Working folder:
  Path: /Users/{operator}/ai-workspace
  Write test: OK

Network:
  github.com: 200 (OK)
  api.anthropic.com: 200 (OK)

Device posture:
  MDM indicators: detected (/Library/Managed Preferences/ populated)
  Time drift: 12 seconds (OK)
  Bash version: 5.2.21 (OK)

Warnings (1):
  - IT-managed device. Some operations may require IT approval.

Continue with install? (y/n, default n)
```

The operator types `y` to proceed or `n` to abort. The pre-flight result is captured in `states.S4_entry.preflight` for the audit trail.

## Per-state procedures

### S4: initial-install-entry

**What the operator sees.** The entry message:

```
[/initial-install]

Welcome to the portable-ai-ecosystem initial install.

I see:
  [x] bootstrap.sh completed     ({timestamp})
  [x] validate-install green     ({path to install-record})
  [ ] no install progress file   (first run)

This is a fresh install. I'll walk you through 11 phases:

  Phase  Name                       Estimated time  Optional?
  -----  ------------------------   --------------  ---------
  4      Entry (this phase)         1 min           no
  5      Tool installation          15-60 min       partly
  6      MCP activation             10-30 min       fully
  7      Hooks + scheduled tasks    10-20 min       fully
  8      Per-device config          5 min           no
  9      Voice customization        5 min - hours   partly
  10     Engagement bootstrap       10-20 min       fully
  11     Final validation           5 min           no

Total optimistic: roughly 60 min. Realistic on a managed device:
3-4 hours spread across days, with IT-approval gates between phases.

You can pause after any phase. I'll persist progress to
.claude/_install-state/state.json. Re-invoke /initial-install any
time to resume.

Reply `continue` to advance to Phase 5, or `pause` to stop here.
```

**Orchestrator action.** Run the pre-flight matrix. Initialize state.json. On `continue`, write state.json with S4 marked completed, advance to S5.

**Exit criteria.** Operator replied `continue`; state.json persisted; pre-flight produced no FAIL on critical checks.

### S5: tool-installation

**What the operator sees.** The tool checklist grouped by tier:

```
Phase 5 of 11 - Tool installation.

Required floor (the framework can't function without these):
  [ ] git                  installed
  [ ] claude               installed and authenticated
  [ ] curl                 standard on macOS and Linux

Recommended for parity (everything works without them, but harder):
  [ ] Homebrew             package manager
  [ ] ripgrep              fast text search
  [ ] jq                   JSON parsing
  [ ] node 18+             needed for Smart Connections MCP build

Optional (only if you want the corresponding capability):
  [ ] Obsidian             markdown editor
  [ ] Drive for Desktop    cross-machine sync (drops the device's
                           local-only guarantee; only for personal machines)

Probe results from this device:
  [x] git 2.39.3
  [x] claude 1.0.42
  [x] curl 8.4.0
  [ ] brew not found
  [ ] rg not found
  [ ] jq not found
  [x] node 20.10.0

Recommended next:
  1. Install Homebrew: /bin/bash -c "$(curl -fsSL ...)"
  2. brew install ripgrep jq

Reply `continue` when ready, `skip` to advance without the recommended
tier, or list the tools you installed so I can re-probe.
```

**Orchestrator action.** For each tool, run a `Bash` probe (`command -v git`, `claude --version`, `command -v brew`, `command -v rg`, `command -v jq`, `node --version`). Track results in `states.S5_tools.details.checklist`. On operator reply, re-probe and update. On `continue`: verify required floor is complete; if not, refuse to advance and surface the gap.

**Exit criteria.** Required-floor tools (`git`, `claude`, `curl`) all `completed`; operator confirmed `continue` or `skip` for the recommended tier.

### S6: mcp-activation (optional)

**What the operator sees.** The MCP menu:

```
Phase 6 of 11 - MCP activation (optional).

MCPs extend Claude Code with external capabilities. The framework
supports several but ships with zero activated. Each activation
has install cost and IT-approval cost on managed devices.

  Smart Connections MCP        Semantic search over vault content
  Session-info MCP             Exposes prior conversation transcripts
  Scheduled-tasks MCP          Programmatic launchd plist management

For each pick, I'll print the activation commands; you run them in a
side terminal. I'll probe claude_desktop_config.json to verify each one.

Reply with picks (e.g., `smart-connections, scheduled-tasks`) or `skip`.
```

**Orchestrator action.** For each pick, print the per-MCP activation procedure (build steps, config-edit instructions). Probe `claude_desktop_config.json` (or the platform equivalent) to verify each MCP server entry. Track per-MCP status in `states.S6_mcp.details.checklist`.

**Exit criteria.** Operator confirmed all picks activated, OR `skip` confirmed.

### S7: hooks-and-tasks

**What the operator sees.** The scheduled-task menu. Operator picks which tasks to enable. Orchestrator delegates to `/wire-hooks-and-tasks`:

```
Phase 7 of 11 - Hooks + scheduled tasks (optional).

Available scheduled tasks:

  Task                          Default cadence   What it does
  ---------------------------   ---------------   ----------------------
  friction-ledger-capture       weekly Friday     Capture session friction
  self-improvement-review       weekly Friday     Synthesize ledger
  process-meeting-transcripts   9:30/12:00/15:00  Ingest from inbox
  workspace-health-check        daily 19:05       Audit vault freshness

Run /wire-hooks-and-tasks now. It will:
  - Print the launchd plist for each task you pick
  - Copy populated plists to ~/Library/LaunchAgents/ with your per-file approval
  - Print the launchctl load command for you to run in a side terminal
  - Probe launchctl list to confirm each agent loaded

When the skill finishes, reply `done` and I'll verify and advance.
```

**Orchestrator action.** Wait for operator to invoke `/wire-hooks-and-tasks`. When `done`, read `skill_runs["wire-hooks-and-tasks"]` from state.json. If `outcome == "success"`, advance. If failed: route to recovery (or accept the operator's explicit skip).

**Exit criteria.** `skill_runs["wire-hooks-and-tasks"].outcome` is `success` or `skipped`.

### S8: per-device-config

**What the operator sees.**

```
Phase 8 of 11 - Per-device config.

Run /initial-setup now. It will walk you through:
  - Framework root (auto-detected)
  - Friction-ledger location
  - Self-improvement-review cadence
  - Voice customization plan
  - Workspace-health-check posture

The skill writes .claude/_setup-state/config.json and appends a row
to Universal/RECORD-decisions/_index.md. Idempotent; safe to revisit later.

When it finishes, reply `done` and I'll verify the config file and advance.
```

**Orchestrator action.** Wait for `/initial-setup` to finish. On `done`, read `.claude/_setup-state/config.json` to confirm it was written and to pick up `voice.personal_md_status` (which determines the S9 branch).

**Exit criteria.** `.claude/_setup-state/config.json` exists; `skill_runs["initial-setup"].outcome == "success"`.

### S9: voice-customization

**What the operator sees.** Branch based on `config.voice.personal_md_status`:

- `framework-author-default`: "You chose to keep the framework author's voice. Continuing." Auto-completes.
- `operator-customized`: "Voice already customized." Auto-completes.
- `operator-pending`: surfaces two sub-paths:

```
Phase 9 of 11 - Voice customization.

Your initial-setup choice for voice was: operator-pending.

Two sub-paths:

  1. Customize now via /operator-voice-bootstrap
     The skill reads your sent emails (Gmail MCP required), extracts
     style observations, regenerates personal.md. It then runs
     change-protocol-sweep to ripple any voice-rule changes.
     Estimated time: 15-40 min.

  2. Defer to after the first engagement
     personal.md keeps the framework-author default. I'll add a TODO
     to the Initial Install record. You commit to regenerating before
     the first customer-facing deliverable.

Which path?
```

**Orchestrator action.** If `framework-author-default` or `operator-customized`: mark S9 completed, advance. If `operator-pending` path 1: wait for `/operator-voice-bootstrap` to finish, then verify `personal.md` no longer has the framework-author header note. If `operator-pending` path 2: mark S9 as `skipped` with `details.deferral_reason: "operator chose to defer"`, advance.

**Exit criteria.** S9 status is `completed` or `skipped`.

### S10: engagement-bootstrap (optional)

**What the operator sees.**

```
Phase 10 of 11 - Engagement bootstrap (optional).

If this device is for a specific client engagement, run
/engagement-bootstrap-from-urls now. It spawns 5 parallel research
agents that read public URLs you provide and produce:

  - Voice Layer 3 (brand voice signals)
  - Initial glossary
  - People roster (public bios only)
  - Product knowledge overview
  - Company thesis

Estimated time: 10-20 min depending on URL count and review depth.

If this is a personal install or you don't have URLs ready, skip.

Reply `bootstrap` to invoke the skill, or `skip` to advance.
```

**Orchestrator action.** Wait for `/engagement-bootstrap-from-urls` to finish. On `done`, verify the engagement-layer paths exist and have content (`voice.md`, `glossary.md`, `thesis.md`, `people.md`, `_overview.md`). Record artifacts in `states.S10_engagement.details.artifacts`.

**Exit criteria.** Engagement-layer paths populated, OR operator confirmed `skip`.

### S11: final-validation

**What the operator sees.**

```
Phase 11 of 11 - Final validation.

I'll re-run /validate-install to confirm everything is wired correctly.
The 6-probe check covers voice composition, initiatives listing,
folder-creation rules, push prevention, pull behavior, and voice
self-attest inside an initiative.

Note: probe 6 only runs if at least one initiative exists. Currently
{0 or N} initiatives are registered. If you'd like probe 6 to fire,
create a stub initiative first via /initiative-kickoff.

When you're ready:
  1. (Optional) /initiative-kickoff to create a stub initiative
  2. /validate-install
  3. Reply `done` and I'll write the Initial Install record.
```

**Orchestrator action.** Wait for `/validate-install` to finish. Read the new install-record. If green, write the Initial Install record (the full audit summary), append the ledger row, mark S11 completed, set `current_state: "DONE"`, print the DONE summary.

**Exit criteria.** `/validate-install` green; Initial Install record written.

## Final report

When S11 exits successfully, the orchestrator prints:

```
Initial install complete.

Summary:
  Phases completed:    {N} of 11
  Phases skipped:      {M} (optional)
  Tools installed:     {list}
  MCPs activated:      {list or "none"}
  Scheduled tasks:     {list or "none (manual-prompt fallback)"}
  Voice plan:          {framework-author-default / operator-customized / operator-pending}
  Engagement layer:    {bootstrapped for {Company} / deferred}

Artifact paths:
  - .claude/_install-state/state.json
  - .claude/_setup-state/config.json
  - Universal/RECORD-decisions/{date} - Install Validation.md
  - Universal/RECORD-decisions/{date} - Initial Install.md
  {if engagement bootstrapped}
  - Universal/FOLLOW-workflows-and-guides/voice/voice.md
  - Universal/READ-references-and-knowledge/glossary.md
  - Universal/READ-references-and-knowledge/thesis.md
  - Universal/READ-references-and-knowledge/people.md
  - Universal/READ-references-and-knowledge/product-knowledge/_overview.md

Next steps:
  - Create your first initiative:  /initiative-kickoff
  - Capture friction at end of day: /friction-ledger-capture
  - Review accumulated friction:    /self-improvement-review

You're done. Welcome to the ecosystem.
```

## Recovery procedures

The 9 critical install-broken failures, each with detection logic, recovery steps, and resume semantics. Cross-references the risk report §2 for the full failure catalog.

### R-1: Claude Code not installed (P-01)

**Trigger.** `which claude` returns nothing at S4 entry or any later state needing claude.

**Recovery.** Print:

```
initial-install requires Claude Code to be installed and on PATH.

1. Install Claude Code: https://docs.anthropic.com/en/docs/claude-code/getting-started
2. Confirm: `which claude` returns a path and `claude --version` returns a version
3. Re-invoke /initial-install
```

Write state.json with `status: "paused-prereq"`, `blocker: "claude-not-installed"`. Release lock. Exit.

### R-2: Claude Code installed but not authenticated (P-02)

**Trigger.** `claude -p "Reply OK"` returns an auth error.

**Recovery.** Print:

```
Claude Code is installed but not authenticated.

1. Run `claude` interactively in a new terminal
2. Type `/login`
3. Complete the OAuth flow in your browser
4. Return here and re-invoke /initial-install

If your browser is blocked by IT (no callback URL allowed):
  - Get your API key from console.anthropic.com
  - export ANTHROPIC_API_KEY=<your-key>
  - Add to ~/.zshrc for persistence
```

Write state.json with `status: "paused-prereq"`, `blocker: "claude-not-authenticated"`. Exit.

### R-3: Working folder occupied (P-08)

**Trigger.** S0-S3 should have caught this, but a re-invocation in the wrong directory hits it.

**Recovery.** Print the matching procedure from risk report §2.3 (three sub-cases: target is our repo, target is another repo, target is non-empty).

Never auto-wipe. Operator decides.

### R-4: Gatekeeper / quarantine block (M-01 + M-02)

**Trigger.** `chmod +x` fails on a hook script, OR `xattr -p com.apple.quarantine` returns a value.

**Recovery.** Print:

```
Detected quarantine attribute on .claude/hooks/session-start.sh.

This often blocks execution under macOS Gatekeeper. Two options:

Option A (preferred, no admin): remove quarantine bit
  xattr -d com.apple.quarantine .claude/hooks/session-start.sh
  xattr -d com.apple.quarantine Universal/RUN-automations/scripts/bootstrap.sh

Option B: invoke via interpreter (bypasses Gatekeeper)
  bash Universal/RUN-automations/scripts/bootstrap.sh
  And in .claude/settings.json, change the hook command from `./hook.sh`
  to `bash hook.sh`
```

Write state.json with `status: "paused-mdm"`, `blocker: "quarantine-or-chmod-block"`. Exit.

### R-5: github.com unreachable (N-01)

**Trigger.** Pre-flight check 8 returns non-2xx for github.com.

**Recovery.** Print:

```
Network probe failed. github.com returned: {status}.

The portable-ai-ecosystem requires outbound HTTPS access to:
- github.com (for git pull updates)
- api.anthropic.com (for Claude Code itself)

File an IT ticket using the template at INSTALL.md §3. Approval is
usually fast because both are standard developer endpoints.
```

Write state.json with `status: "paused-network"`, `blocker: "github-unreachable"`. Exit.

### R-6: TLS / MITM proxy (N-04)

**Trigger.** Pre-flight check 8 or 9 returns a TLS error rather than a network error.

**Recovery.** Print:

```
Detected TLS interception. Your corporate network uses a proxy that
re-signs HTTPS traffic. Work around it:

1. Get the corporate CA bundle from IT
2. git config --global http.sslCAInfo /path/to/ca-bundle.pem
3. export NODE_EXTRA_CA_CERTS=/path/to/ca-bundle.pem (add to shell config)
4. Re-invoke /initial-install
```

Write state.json with `status: "paused-network"`, `blocker: "tls-mitm-detected"`. Exit.

### R-7: Clone interrupted (N-06)

**Trigger.** `git -C {framework_root} fsck --quiet` fails, OR expected framework files are missing.

**Recovery.** Print:

```
Detected an incomplete or corrupted clone at {framework_root}.

Recommended recovery: wipe and re-clone.

  rm -rf {framework_root}
  git clone https://github.com/{handle}/portable-ai-ecosystem.git {framework_root}

If you've done work under {framework_root}/Initiatives/ already, back
it up first.
```

Write state.json (if state.json is still readable) with `status: "error"`, `blocker: "clone-corrupted"`. Exit. The operator may need to delete state.json manually before re-invocation if the wipe is total.

### R-8: Working folder not writable (PR-01)

**Trigger.** Pre-flight check 7 fails.

**Recovery.** Print:

```
Cannot write to {framework_root}.

Options:

1. Choose a different folder under your home directory and re-clone:
   - ~/dev/ai-workspace
   - ~/Documents/ai-workspace

2. If your home directory itself denies writes, file an IT ticket.

3. If you're on a managed device with a special user-writable area,
   use that instead.
```

Write state.json with `status: "paused-prereq"`, `blocker: "workdir-not-writable"`. Exit.

### R-9: validate-install crashes (V-05)

**Trigger.** At S3 or S11, `/validate-install` errors out without writing an install-record.

**Recovery.** Print:

```
/validate-install failed to run. This usually means the clone is
incomplete or the .claude/skills/ layout is wrong.

Verification:
  ls .claude/skills/validate-install/SKILL.md

If "no such file", re-pull:
  cd {framework_root} && git pull

Then restart Claude Code (so skill discovery re-runs) and re-invoke
/initial-install.
```

Write state.json with `status: "error"`, `blocker: "validate-install-broken"`. Exit.

## Idempotency model

The skill is re-invocable at any point without side effects beyond progress tracking. The rules:

### Single source of truth

state.json is the source of truth for progress. The skill prefers state.json over filesystem probes for the question "what state am I in?" Filesystem probes serve as sanity checks (see Step 4 reconciliation in the SKILL.md).

### Atomic writes

Every state.json update uses the temp-and-rename pattern:

```bash
tmp=$(mktemp "{state_file}.XXXXXX")
{updated_json} > "$tmp"
mv "$tmp" "$state_file"
```

This protects against partial writes during Ctrl+C, terminal disconnect, or crash. The most recent atomic write is always the operator's checkpoint.

### Lock file

`.claude/_install-state/.lock` contains `{pid, started_at}`. The skill acquires the lock at Step 3 and releases on clean exit. Stale locks (PID no longer running, or file older than 1 hour) are reclaimed with a warning. Concurrent `claude` sessions touching state.json are refused.

### Per-state idempotency

Every state must be safely replayable:

- S4 entry: writing state.json overwrites; pre-flight matrix re-runs cheaply
- S5 tool-installation: probes are read-only; tools install commands are idempotent at the OS level (Homebrew, npm)
- S6 mcp-activation: config-file edits are operator-driven and idempotent
- S7 hooks-and-tasks: `launchctl load` is idempotent (no-op if already loaded); plist writes are overwrite-safe with operator approval
- S8 per-device-config: `/initial-setup` is idempotent per its own design
- S9 voice-customization: `/operator-voice-bootstrap` writes to a staging area before committing to personal.md; cancellation leaves no partial state
- S10 engagement-bootstrap: `/engagement-bootstrap-from-urls` is idempotent per its own design (same URLs produce same output)
- S11 final-validation: `/validate-install` writes a new dated install-record each run; idempotent

### Resume detection

On re-invocation:

1. state.json missing → first run; initialize fresh
2. state.json present with `current_state: "DONE"` → install complete; offer revisit menu
3. state.json present with any other `current_state` → resume at `current_state`, after reconciliation
4. state.json corrupted → back up, prompt operator, offer rebuild from on-disk evidence

### Replay semantics

`/initial-install replay {N}`: mark state N and all states after as `pending`, clear their `completed_at` and `artifact` fields, set `current_state = "S{N}"`, advance. This is the operator's escape hatch for redoing a phase after a config change or `git pull`.

### Jump-forward escape hatch

Advanced operators can `jump forward` past pending states. Surfaces a one-line warning per skipped state. The skipped states are marked `skipped` with `details.skipped_reason: "operator jumped forward"` so the audit trail is intact.

## Sub-skill delegation contract

The orchestrator does not invoke sub-skills programmatically. It prints `/{sub-skill-name}` and waits for the operator to send it. The operator and the sub-skill complete the phase; on `done`, the orchestrator reads the sub-skill's `skill_runs[{name}]` block from state.json to determine outcome.

| Sub-skill | Phase | Reads from state.json | Writes to state.json |
|---|---|---|---|
| `validate-install` | S3, S11 | `orchestrator_active` flag; suppresses next-step prompts when true | `skill_runs.validate-install` block |
| `initial-setup` | S8 | `orchestrator_active` flag | `skill_runs.initial-setup` block; also `.claude/_setup-state/config.json` |
| `engagement-bootstrap-from-urls` | S10 | `orchestrator_active` flag | `skill_runs.engagement-bootstrap-from-urls` block; engagement-layer files |
| `operator-voice-bootstrap` | S9 path C | `orchestrator_active` flag | `skill_runs.operator-voice-bootstrap` block; `personal.md` |
| `wire-hooks-and-tasks` | S7 | `orchestrator_active` flag | `skill_runs.wire-hooks-and-tasks` block; per-task launchd plists |

Each sub-skill's SKILL.md documents its own state.json participation. The orchestrator never writes the sub-skill's block; the sub-skill never writes the orchestrator's `current_state` or `completed_states`.

## Halt template

When the skill halts (cannot recover automatically and cannot continue without operator action), it prints:

```
=== initial-install halted ===

Step: {state-id}
Reason: {one-line summary}
Detail: {verbatim error output or command output}

What I tried:
  - {command 1}
  - {command 2}

What you can do:
  Option A: {recovery action from the matching R-N procedure}
  Option B: {alternative}
  Option C: {abort and clean state}

State saved at .claude/_install-state/state.json
Re-invoke /initial-install when ready. It will resume from this state.

Documentation:
  - Troubleshooting: INSTALL.md §8
  - Playbook: Universal/FOLLOW-workflows-and-guides/playbooks/initial-install.md
  - Friction ledger: /friction-ledger-capture
```

The halt template surfaces specifics (no "something went wrong"), names the failing step, includes the verbatim error, lists what was tried, gives concrete next actions, and points at documentation. The operator never wonders "what happened?"

## Cross-references

- Skill runtime: `Universal/RUN-automations/skills/initial-install/SKILL.md`
- Workflow architecture (the design rationale): `Universal/PRODUCE-outputs/research/portable-ai-ecosystem-research/initial-install-research/02-workflow-architecture.md`
- Risk and failure modes (the full 52-failure catalog + recovery procedures): `Universal/PRODUCE-outputs/research/portable-ai-ecosystem-research/initial-install-research/05-risks-and-failure-modes.md`
- Engagement-layer activation (Track A + Track B design): `Universal/PRODUCE-outputs/research/portable-ai-ecosystem-research/initial-install-research/04-engagement-layer-activation.md`
- Tool inventory (the S5 checklist source of truth): `Universal/PRODUCE-outputs/research/portable-ai-ecosystem-research/initial-install-research/01-tool-inventory.md`
- Parity-gap analysis (what the install achieves vs the framework-author baseline): `Universal/PRODUCE-outputs/research/portable-ai-ecosystem-research/initial-install-research/03-parity-gap-analysis.md`
- Sub-skill: `validate-install` (S3, S11)
- Sub-skill: `initial-setup` (S8)
- Sub-skill: `engagement-bootstrap-from-urls` (S10) and its playbook `engagement-bootstrap-from-urls.md`
- Sub-skill: `operator-voice-bootstrap` (S9 path C)
- Sub-skill: `wire-hooks-and-tasks` (S7)
- Decisions ledger format: `Universal/FOLLOW-workflows-and-guides/playbooks/change-protocol.md` §"Decisions ledger interaction"
- Folder creation rules: `Universal/FOLLOW-workflows-and-guides/playbooks/folder-creation-rules.md`
- Framework overview: `Universal/FOLLOW-workflows-and-guides/playbooks/portable-ai-ecosystem.md`
