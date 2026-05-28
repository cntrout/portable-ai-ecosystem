---
name: wire-hooks-and-tasks
description: Generates `launchd` user agent plist files from the per-device cadence preferences in `.claude/_setup-state/config.json`, loads them into user-level launchd, and verifies they are scheduled correctly. Wires up scheduled invocation for `friction-ledger-capture`, `self-improvement-review`, and any other recurring framework skills the operator opted into during `initial-setup`. Idempotent and re-runnable; re-run after changing cadence in `initial-setup`. Use after `initial-setup` and `engagement-bootstrap-from-urls` complete and the operator wants their scheduled tasks live.
allowed-tools: Read, Write, Edit, Bash, Glob, Grep
---

# Wire Hooks and Tasks

Generates and loads macOS `launchd` user agents so the framework's recurring skills fire on the cadence the operator chose in `initial-setup`. Without this skill, those cadences are aspirational; the operator has to remember to invoke each skill manually. With this skill, the OS does the invoking on schedule via `claude -p`.

The empirical test on 2026-05-27 confirmed `launchd` can invoke `claude -p` non-interactively without a TTY and without an auth blocker, so the pattern in this skill is validated rather than speculative.

## When this skill fires

The operator just finished `initial-setup` (so `.claude/_setup-state/config.json` exists and has cadence preferences) and wants the scheduled invocations to actually fire on cadence. Also fires when the operator changes a cadence later in `initial-setup` and wants the plist updated to match.

Re-running this skill is safe. It detects existing plists, compares them against the current config, and only rewrites or reloads what changed.

## What this skill does NOT do

- Does not configure cadence preferences (that's `initial-setup`)
- Does not validate the install (that's `validate-install`)
- Does not check the underlying skills work (run them manually first if you're unsure they fire correctly)
- Does not install Claude Code, Homebrew, or any system tool (that's the operator's job in a terminal)
- Does not edit any system file outside `~/Library/LaunchAgents/` and the local-state JSON files

## Pre-flight checks

Before generating any plist, confirm:

1. **Per-device config exists.** Read `.claude/_setup-state/config.json`. If missing, abort with: "Run `/initial-setup` first to capture your cadence preferences." If the file exists but is malformed JSON, surface the parse error and abort.

2. **`launchctl` is available.** Run `command -v launchctl`. On macOS this is always present. If the skill is invoked on Linux or another OS, surface that `launchd` is macOS-only and exit cleanly with a pointer to the manual-prompt fallback.

3. **`~/Library/LaunchAgents/` is writable.** Run `[ -w "$HOME/Library/LaunchAgents" ] || mkdir -p "$HOME/Library/LaunchAgents"`. If the directory cannot be created or written, surface the permission error and abort.

4. **Each target skill exists at the expected path.** For each skill the config schedules, confirm `.claude/skills/{skill-name}/SKILL.md` exists. If a skill is scheduled but its SKILL.md is missing, surface the gap and skip that skill's plist generation.

5. **`claude` binary resolvable.** Run `which claude` and capture the absolute path. If the command returns nothing, surface "Claude Code not on PATH; add it before re-running this skill." and abort.

## Steps

### Step 1: Read config.json and extract cadences

Read `.claude/_setup-state/config.json`. For each skill the framework supports on a cadence, pull its cadence block. The v1.2 schedule covers:

- `config.friction_ledger.capture_cadence` (if present; defaults to `daily` per `initial-setup`)
- `config.self_improvement_review.cadence` (with `.day_of_week` when weekly)

Future cadences (workspace-health-check in v1.3) will follow the same shape.

Build an internal table of `{skill-name, cadence, day-of-week-if-applicable, time-of-day}`. Default time of day is `09:00` local. Surface the table to the operator before generating any files and ask for confirmation.

### Step 2: Resolve absolute path to the `claude` binary

Run `which claude` and capture the output. Store as `CLAUDE_PATH`. Verify the path exists and is executable: `[ -x "$CLAUDE_PATH" ]`. The plist needs an absolute path; relative paths or PATH lookups do not work reliably under `launchd`.

If `claude` is at a non-standard location (homebrew prefix, custom `~/.local/bin`), record that in the operator-facing summary so the operator can sanity-check.

### Step 3: Resolve repo root and operator handle

Run `git rev-parse --show-toplevel` from the working directory to get `REPO_ROOT`. This is the framework folder the plist will `cd` into before invoking `claude -p`.

For the plist `Label` field, build a handle: prefer `config.operator_handle` if `initial-setup` captured one; otherwise fall back to `$(whoami)`. The label format is `com.{operator}.{skill-name}`. The label is what `launchctl list` returns and what the operator uses to unload the agent later.

### Step 4: Generate each plist

For each scheduled skill in the table from Step 1, render the plist template (see "Plist template" section below) with these substitutions:

- `{LABEL}` becomes `com.{operator}.{skill-name}`
- `{CLAUDE_PATH}` becomes the path from Step 2
- `{SKILL_NAME}` becomes the skill name (used in the `-p` prompt)
- `{REPO_ROOT}` becomes the path from Step 3
- The schedule block becomes either `StartCalendarInterval` (daily, weekly, monthly) or `StartInterval` (sub-daily) per the cadence mapping below
- `{LOG_DIR}` becomes `~/Library/Logs/portable-ai-ecosystem`

Write each rendered plist to `~/Library/LaunchAgents/{LABEL}.plist`. If the file already exists with different content, save the existing version to `{LABEL}.plist.bak.{timestamp}` before overwriting and tell the operator a backup was made.

Ensure `~/Library/Logs/portable-ai-ecosystem/` exists; create it if not.

### Step 5: Validate each plist with `plutil -lint`

Run `plutil -lint ~/Library/LaunchAgents/{LABEL}.plist` for each file written. If the lint fails, surface the plutil error verbatim, delete the bad plist, and skip the load step for that skill. A bad plist that gets loaded can put `launchd` into a state that needs `launchctl bootstrap` to recover, which is more friction than the operator should have to handle.

### Step 6: Load each plist via `launchctl`

For each lint-passing plist, run `launchctl load ~/Library/LaunchAgents/{LABEL}.plist`. If the job is already loaded (operator re-running this skill after a cadence change), run `launchctl unload` first, then `load`. Surface any error from `launchctl` verbatim to the operator.

On macOS Catalina and later, `launchctl load` may report deprecation warnings pointing at `launchctl bootstrap`. The deprecated form still works as of macOS 14; the skill uses `load`/`unload` for compatibility with older versions and surfaces the warning to the operator without acting on it.

### Step 7: Verify each load via `launchctl list`

Run `launchctl list | grep {LABEL}` for each loaded agent. A successful load returns a line with the PID (or `-` if the job hasn't fired yet), exit status (typically `0` after first run), and the label. If `grep` returns nothing, the load silently failed; surface that to the operator and offer to retry.

### Step 8: Write a record to state.json

If `.claude/_install-state/state.json` exists (the orchestrator is active), update the `skill_runs["wire-hooks-and-tasks"]` block per the state-file participation pattern. If state.json does not exist, skip this step (stand-alone invocation).

### Step 9: Print next-step pointers

Report a summary to the operator:

- Which plists were written and loaded
- Where stdout and stderr logs land (`~/Library/Logs/portable-ai-ecosystem/{skill-name}.stdout.log` and `.stderr.log`)
- How to verify a run fired: `tail -f ~/Library/Logs/portable-ai-ecosystem/{skill-name}.stdout.log` after the next scheduled time
- How to unload an agent (see "Unloading" section below)
- Pointer to the empirical-test result document validating the pattern

## Plist template

The template below is the working pattern validated by the 2026-05-27 empirical test on macOS 14 (Darwin 25.3.0). Substitution placeholders are in `{CURLY_BRACES}`.

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>{LABEL}</string>

    <key>ProgramArguments</key>
    <array>
        <string>{CLAUDE_PATH}</string>
        <string>-p</string>
        <string>Run the {SKILL_NAME} skill.</string>
    </array>

    <key>WorkingDirectory</key>
    <string>{REPO_ROOT}</string>

    {SCHEDULE_BLOCK}

    <key>StandardOutPath</key>
    <string>{LOG_DIR}/{SKILL_NAME}.stdout.log</string>

    <key>StandardErrorPath</key>
    <string>{LOG_DIR}/{SKILL_NAME}.stderr.log</string>

    <key>RunAtLoad</key>
    <false/>

    <key>EnvironmentVariables</key>
    <dict>
        <key>PATH</key>
        <string>/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin</string>
    </dict>
</dict>
</plist>
```

The `{SCHEDULE_BLOCK}` is one of:

```xml
<key>StartCalendarInterval</key>
<dict>
    <key>Hour</key><integer>9</integer>
    <key>Minute</key><integer>0</integer>
</dict>
```

for `daily`, or with an added `Weekday` integer for `weekly` (see mapping below), or with an added `Day` integer for `monthly`. For sub-daily cadences, use `StartInterval` with an integer seconds value instead.

`RunAtLoad` is set to `false` so reloading the plist doesn't trigger an immediate run; the operator can override locally if they want a smoke test by setting it to `true` and reloading.

## Cadence to launchd mapping

| Cadence in config.json | Plist schedule block | Notes |
|---|---|---|
| `daily` | `StartCalendarInterval` with `Hour=9 Minute=0` | Morning trigger. Operator can override the time in config.json if they prefer evening. |
| `weekly` with `day_of_week` | `StartCalendarInterval` with `Weekday=N Hour=9 Minute=0` | Weekday integer: Sunday=0, Monday=1, Tuesday=2, Wednesday=3, Thursday=4, Friday=5, Saturday=6. |
| `biweekly` | Not natively supported by launchd. | Workaround: use the weekly mapping plus a guard inside the target skill that reads its own last-run timestamp and exits early if fewer than 14 days have passed. Document this in the operator-facing summary. |
| `monthly` | `StartCalendarInterval` with `Day=1 Hour=9 Minute=0` | First of the month at 09:00. |
| `manual-only` | No plist generated | Skipped during plist generation; surfaced in the summary as "manual-only; no scheduled invocation". |

When the operator's config has an unknown cadence value, surface it as a gap and skip that skill's plist; do not guess.

## Logging

Each plist routes stdout and stderr to per-skill files under `~/Library/Logs/portable-ai-ecosystem/`:

- `~/Library/Logs/portable-ai-ecosystem/{skill-name}.stdout.log`
- `~/Library/Logs/portable-ai-ecosystem/{skill-name}.stderr.log`

The skill creates the log directory if missing (`mkdir -p`). Both files grow without bound; rotating logs is not in scope for v1.2. If a log grows beyond a few megabytes (rare for `claude -p` output), the operator can `> {file}` to truncate it without affecting the running schedule.

Empty stderr after a run is the success signal. Non-empty stderr typically means either the `claude` invocation failed (auth, PATH, working-directory issues) or the underlying skill itself emitted an error. The operator triages by reading stderr first, then stdout for context.

## State-file participation

Mirrors the pattern used by `initial-setup`. If the `initial-install` orchestrator is active (`.claude/_install-state/state.json` exists with `orchestrator_active: true`), this skill writes its own per-skill block to that file on completion. If the orchestrator is not active, the skill behaves identically except it skips the state.json write.

### When state.json exists

1. **Read state.json at start.** Path: `{REPO_ROOT}/.claude/_install-state/state.json`. Record locally that this skill is running under the orchestrator.

2. **Use the lock file convention.** Before writing to state.json, check for `{REPO_ROOT}/.claude/_install-state/.lock`. If the lock exists and its modification time is fresher than 5 minutes, wait briefly and re-check, or abort the state.json write. Plist generation and `launchctl` operations still happen regardless of the lock; only the state.json update is gated.

3. **Write the per-skill block on completion.** Update `state.json` with a `skill_runs["wire-hooks-and-tasks"]` block:

   ```json
   {
     "last_run_at": "2026-MM-DDTHH:MM:SS",
     "outcome": "success",
     "summary": "loaded 2 of 2 agents: friction-ledger-capture (daily 09:00), self-improvement-review (weekly Friday 09:00)",
     "invoked_by": "orchestrator"
   }
   ```

   Outcome values:
   - `success`: every plist that should have been generated was generated, validated, and loaded
   - `partial`: at least one plist generated and loaded successfully, at least one failed or was skipped
   - `failed`: no plists loaded (e.g., `launchctl` unavailable, `~/Library/LaunchAgents/` not writable)
   - `skipped`: operator declined to load any plists (e.g., chose all-manual-only)

4. **Atomic write.** Use the `mktemp` + `mv` pattern so a partial write never corrupts state.json:

   ```bash
   tmp=$(mktemp "$STATE_FILE.XXXXXX")
   {updated_json} > "$tmp"
   mv "$tmp" "$STATE_FILE"
   ```

## Failure handling

| Failure | What the skill does | What to surface |
|---|---|---|
| `which claude` returns nothing | Abort before any plist generation | "Claude Code not on PATH. Add `claude` to PATH (typically via the installer's documented location) and re-run." |
| `~/Library/LaunchAgents/` not writable and `mkdir -p` fails | Abort | The OS permission error verbatim, plus pointer to check if the operator's user account has been restricted by IT policy. |
| `plutil -lint` reports a malformed plist | Skip the load step for that skill; delete the bad plist | The plutil error verbatim. Likely a substitution bug; ask the operator to file the issue with the rendered plist contents. |
| `launchctl load` reports "service already loaded" | Run `launchctl unload` first, then `load` again | Treat as expected; this happens on re-runs after a cadence change. |
| `launchctl load` reports a syntax error after `plutil` passed | Skip and continue with remaining plists | Surface the launchctl error verbatim. Rare; usually means the plist is structurally fine but uses a key launchd doesn't accept on this macOS version. |
| `launchctl list | grep {LABEL}` returns nothing after load | Surface as a verify failure; offer to retry | Most commonly means the load silently failed because the file's permission bits are wrong (the file must be readable by the user). Run `chmod 644` on the plist and retry. |
| MDM blocks launchd user agents | Catch the `launchctl` error pattern and degrade gracefully | "Your device's MDM policy blocks loading user agents. Use the manual-prompt fallback: invoke each skill yourself at the cadence you chose. The cadence preferences in `.claude/_setup-state/config.json` are still recorded for future reference." |
| The target skill's SKILL.md is missing from `.claude/skills/{skill-name}/` | Skip that skill's plist; do not generate a plist that would invoke a non-existent skill | "Skill `{skill-name}` is scheduled in config but no SKILL.md found at the expected path. Run `/validate-install` to check the install state." |

## Unloading

When the operator wants to pause a scheduled task without re-running this skill (e.g., during PTO, or while debugging a misbehaving skill), they unload the agent directly:

```bash
launchctl unload ~/Library/LaunchAgents/com.{operator}.{skill-name}.plist
```

The plist file stays on disk. To resume, `launchctl load` the same path. To permanently remove the schedule, unload the agent and delete the plist file.

To unload everything this skill installed in one shot:

```bash
for f in ~/Library/LaunchAgents/com.{operator}.*.plist; do launchctl unload "$f"; done
```

Substitute the operator handle. The skill prints the exact command in the Step 9 summary with the handle prefilled.

## Re-invocation

Safe to re-run any time. The skill detects existing plists by label, compares their content against what it would generate fresh, and only rewrites and reloads what changed. If nothing changed since the last run, the skill reports "no changes; all agents still loaded" and exits.

A common reason to re-run: the operator went back into `initial-setup` and changed a cadence (e.g., moved `self-improvement-review` from weekly Friday to monthly). After saving the new config, they re-invoke this skill to regenerate the affected plist.

## Cross-references

- `initial-setup`: reads cadence preferences from `.claude/_setup-state/config.json` that this skill writes
- `friction-ledger-capture`: skill that this skill schedules (typically daily)
- `self-improvement-review`: skill that this skill schedules (typically weekly)
- `initial-install`: orchestrator that delegates to this skill at State 7 of the install flow
- 2026-05-27 launchd headless test results: `Universal/PRODUCE-outputs/research/portable-ai-ecosystem-research/empirical-tests/2026-05-27 - Launchd Headless Test Results.md`
- Workflow architecture report's State 7 design: `Universal/PRODUCE-outputs/research/portable-ai-ecosystem-research/initial-install-research/02-workflow-architecture.md`
