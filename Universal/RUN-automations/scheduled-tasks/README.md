# Universal/RUN-automations/scheduled-tasks/

**Purpose:** Home for launchd plist templates and per-task configuration that drives recurring skill invocations on this device. One subfolder per scheduled task; each subfolder contains the plist template, an install procedure, and any per-task config the skill needs at runtime.

## What lives here

One subfolder per task the operator wants to run on a cadence, named with the same slug as the skill the task invokes. For example:

- `friction-ledger-capture/`: plist + install notes for the daily friction-ledger run.
- `self-improvement-review/`: plist + install notes for the weekly review.
- `process-meeting-transcripts/`: plist + install notes when a meeting source is configured and the operator wants the skill to run on a cadence.

Each subfolder typically contains:

- `plist.template`: the launchd plist with placeholder values (operator path, Python path, task slug).
- `README.md`: install procedure for this specific task.
- Optional per-task runtime config files.

## What does not live here

- The skill's own definition lives in `../skills/{skill-slug}/SKILL.md`. This folder is about the cadence and the launchd wiring, not the skill itself.
- Outputs of scheduled runs belong wherever the skill writes them (typically a folder named after the skill under `PRODUCE-outputs/machine-generated/` or similar). Outputs do not belong here.
- One-shot operator-invoked scripts that are not on a cadence belong in `../scripts/` if such a folder exists.

## Lifecycle

Accreting at the folder level (one new subfolder per task the operator decides to schedule). Each per-task subfolder is stable once installed; the plist template rarely changes unless the cadence or the skill path changes.

## Naming convention

Subfolder slug matches the skill slug exactly. Plist file names follow the launchd convention `com.{operator-handle}.{task-slug}.plist` once installed at `~/Library/LaunchAgents/`. The template inside this folder uses `plist.template` so it ships safely in the repo without colliding with installed plists.

## Install procedure (general shape)

1. Copy `plist.template` to a working location, substitute the placeholder values for paths on this device.
2. Save the result to `~/Library/LaunchAgents/com.{operator}.{task-slug}.plist`.
3. Run `launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.{operator}.{task-slug}.plist` to register it.
4. Confirm registration with `launchctl print gui/$(id -u)/com.{operator}.{task-slug}`.

Per-task READMEs spell out the exact substitution and any task-specific verification step.

## Cross-references

- `Universal/RUN-automations/skills/_index.md`: the registry of skills that can be scheduled.
- `Universal/FOLLOW-workflows-and-guides/playbooks/automation-schedule.md`: the operator's chosen cadences and their rationale.
- `Universal/FOLLOW-workflows-and-guides/playbooks/external-tool-approval.md`: launchd is a system-level surface; the approval gate is light but documented there.

## Lifecycle stance for v1.2 first install

Folder ships empty with this README only. The `wire-hooks-and-tasks` skill (added in v1.2) generates per-task plists from the operator's `initial-setup` cadence choices and loads them via `launchctl`. Ready-to-copy plist templates for the recurring framework skills land in v1.3 alongside the `workspace-health-check` skill port. Until then, operators who want a cadenced task either run `/wire-hooks-and-tasks` (preferred) or author a plist by hand using this README as the shape guide.
