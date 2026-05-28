---
name: friction-ledger-capture
description: Phase 1 of the self-improvement loop. Reviews recent Claude sessions for behavioral friction (places where Claude's behavior diverged from what the operator wanted) and appends generalized observations to the friction ledger. Capture-only: the only file this skill ever modifies is the ledger itself. Pairs with the `self-improvement-review` skill (Phase 2), which reads the ledger and proposes edits to system files. Invoke manually for now; a launchd user agent can run it on a cadence in a future version.
allowed-tools: Read, Write, Edit, Glob, Grep
---

You are the friction-capture step of the self-improvement loop (Phase 1). Your job is to review recent Claude sessions for moments where Claude's behavior diverged from what the operator wanted, and append generalized behavioral observations to the friction ledger. You are CAPTURE-ONLY: the only file you ever modify is the friction ledger.

## Context

You run inside the framework's working folder. Resolve it with `git rev-parse --show-toplevel`; all paths in this skill are relative to that root.

The friction ledger lives at the path set by the per-device `initial-setup` skill. The default is `Universal/PRODUCE-outputs/friction-ledger.md`. If that path doesn't exist, look for a `friction-ledger.md` anywhere under `Universal/PRODUCE-outputs/` before giving up. Abort with a clear message if the ledger cannot be located; do not create it from this skill (the template ships with the repo and is placed by `initial-setup`).

This skill is the capture phase. A sibling skill, `self-improvement-review`, runs the synthesis phase on a longer cadence and proposes edits to system files based on accumulated entries. The split is deliberate: capture is cheap and append-only; synthesis is expensive and propose-only.

## MCP availability

MCP availability varies per device. This skill prefers a session-info MCP (or equivalent) that exposes `list_sessions` and `read_transcript`. If those tools aren't available in the current environment, degrade gracefully: report that transcript review isn't possible on this device and exit without writing to the ledger.

When MCP tools are present, do the transcript work inside a spawned subagent (Task tool). Subagents get clean MCP initialization, which avoids race conditions when the skill is launched via a scheduler before connectors finish coming up.

## Steps

1. Read the friction ledger. Note `last_processed_session` in its frontmatter.
2. Spawn a subagent to do steps 2a through 2d.
   - 2a. Call the session-info `list_sessions` tool (limit 40). Sessions return most-recent-first.
   - 2b. Select the idle, top-level sessions (`is_child: false`) that appear above `last_processed_session` in the list (more recent than it). If the watermark is `none` (first run), select only the single most recent idle top-level session. Do not backfill history. Skip this skill's own run and any other automation runs by title (anything that looks like a scheduled-task or system-maintenance session, not a user-driven one).
   - 2c. For each selected session, call `read_transcript` and look for friction signals.
     - **explicit-feedback:** the operator told Claude to behave differently going forward ("next time", "always", "stop doing", "from now on").
     - **violated-rule:** Claude broke a rule already in CLAUDE.md, AGENTS.md, or a SKILL.md.
     - **correction:** the operator corrected Claude's output or approach mid-task.
     - **re-explanation:** the operator re-explained something a system rule should already cover.
   - 2d. For each genuine friction moment, produce a GENERALIZED behavioral observation. PARTITION RULE, CRITICAL: record only generalized behavior. Never write client names, client facts, numbers, deliverable contents, or any project-specific detail. State it as "Claude did X; the operator wanted Y." If a moment cannot be stated without project-specific specifics, drop it.
3. Append each observation to the `## Entries` section of the ledger, using the entry format documented inside that file, dated today. If there is no genuine friction, append nothing.
4. Update `last_processed_session` in the ledger frontmatter to the most recent idle top-level session you saw this run.
5. Post a short summary: how many sessions reviewed and how many observations captured (or "no friction captured today").

## Rules

- Capture-only. Never edit CLAUDE.md, AGENTS.md, any SKILL.md, or any other system file. The friction ledger is the only file this skill modifies.
- Be conservative. When unsure whether something is real friction, skip it. A quiet day with no entries is a fine outcome.
- Generalized behavior only. The ledger is operator-agnostic by construction and must never contain project-specific content.
- The watermark advances on every run, even when no entries are captured, so the next run doesn't reprocess the same sessions.
