---
name: self-improvement-review
description: Phase 2 of the self-improvement loop. Reads the friction ledger, groups recent observations into patterns, and proposes concrete edits to system files (rules, playbooks, voice files, AGENTS/CLAUDE) for the operator to triage in chat. Propose-only by design: no system file is ever modified without explicit per-item approval, and Risk class 0 files (root rule files) are never auto-applied under any circumstances. Pairs with `friction-ledger-capture` (Phase 1). Invoke manually for now; a launchd user agent can run it on a cadence in a future version.
allowed-tools: Read, Write, Edit, Glob, Grep
---

You are the synthesis step of the self-improvement loop (Phase 2). Your job is to read the friction ledger, find patterns worth acting on, propose concrete improvements to the operator's system files, and let the operator triage those proposals with you in this chat. You are PROPOSE-ONLY: no system file is ever edited without the operator's explicit approval in this chat.

## Context

You run inside the framework's working folder. Resolve it with `git rev-parse --show-toplevel`; all paths below are relative to that root.

The friction ledger (written by the `friction-ledger-capture` skill, Phase 1) lives at the path set by the per-device `initial-setup` skill. The default is `Universal/PRODUCE-outputs/friction-ledger.md`. If that path doesn't exist, look for a `friction-ledger.md` anywhere under `Universal/PRODUCE-outputs/` before giving up. Abort with a clear message if the ledger cannot be located.

The underlying design rationale for the two-phase loop lives in a separate research doc inside this repo. You don't need it to do this job; the steps below are self-contained.

## System files in scope, with risk classes

Risk class labels rank the cost of getting an edit wrong. Higher class means higher blast radius and stricter approval requirements. (Distinct from change-protocol.md's Tier 1 / Tier 2 classification, which tracks verification process; here Risk class tracks automated-change risk.)

- **Risk class 0 (highest risk, propose-only ALWAYS, never auto-applied under any circumstances):**
  - Root `AGENTS.md` and its byte-identical sibling `CLAUDE.md`
  - `Universal/AGENTS.md` and `Universal/CLAUDE.md` (if present)
  - Per-initiative `Initiatives/{slug}/CLAUDE.md` if present (rare; most initiatives don't carry their own AGENTS/CLAUDE)
- **Risk class 1 (framework rules and voice):**
  - `Universal/FOLLOW-workflows-and-guides/voice/` files
  - Core playbooks in `Universal/FOLLOW-workflows-and-guides/playbooks/`
- **Risk class 2 (working content):**
  - `SKILL.md` files under `.claude/skills/{name}/`
  - Slash commands in `.claude/commands/`
- **Risk class 3 (reference material):**
  - `Universal/READ-references-and-knowledge/concepts/`
  - `Universal/READ-references-and-knowledge/frameworks/`
  - `Universal/READ-references-and-knowledge/glossary/`

Risk class 0 edits require explicit per-item approval in this chat. Risk class 0 is never batched and never silent.

## MCP availability

If a proposal would benefit from MCP tools (for example, looking up a related project tracker entry or pulling a transcript), do that work through a spawned subagent (Task tool). Reading vault files directly with `Read`, `Glob`, and `Grep` is fine and is the common case.

## Steps

1. Read the friction ledger, including any `## Review log` section at the bottom. Past dispositions live there; do not re-propose anything already dispositioned.
2. Group the observations into patterns. Apply the recurrence threshold: a pattern becomes a proposal only if it recurs across at least 3 distinct observations on at least 3 distinct days. EXCEPTION: a single explicit-feedback observation (the operator said "always," "never," or "next time") may become a proposal on its own, since the operator has already generalized it.
3. For each qualifying pattern, draft a proposed change with:
   - the target file and its risk tier
   - the problem in one or two sentences
   - the supporting evidence (which ledger entries, by date)
   - a concrete suggested edit (the exact text to add or change, as a before/after)
   - a contradiction check against current `AGENTS.md` / `CLAUDE.md` and other rule files; if the change conflicts with an existing rule, say so and propose resolving the conflict, not just adding
   - a paired prune suggestion if the change adds to a context file, since those files must stay lean
4. Present all proposals in THIS chat, numbered, for the operator to triage. The operator responds with "apply #N", "apply #N with this change", "skip #N", or "defer #N".
5. On "apply": make the edit. Respect the edit-time sync rules.
   - If you edit `AGENTS.md`, save the byte-identical change to its `CLAUDE.md` sibling in the same change.
   - If you edit a file under `.claude/skills/{name}/`, add a `CHANGELOG.md` line in the same change.
   - If the edit touches a system file listed in `Universal/FOLLOW-workflows-and-guides/playbooks/change-protocol.md`, run the doc-sync ripple sweep per that playbook: tight-couple updates inline; wider sweep batches at the end of triage; prompt for batch approval at natural pauses.
   - Risk class 0 files: edited ONLY after explicit per-item approval in this chat. Never silently. Never as a batch.
6. After triage, append a dated record to a `## Review log` section at the bottom of the friction ledger (create the section if absent). Record what was proposed and how the operator dispositioned each item. This closes the loop and prevents re-proposing the same pattern next run.
7. If the ledger has no qualifying patterns, say so briefly and stop. A quiet week is a fine outcome.

## Rules

- Propose-only. Never edit a system file without the operator's explicit approval in this chat. Risk class 0 files are never auto-applied under any circumstances.
- Never edit your own governance: do not propose changes that weaken this loop's review step, the partition rules, or the conservative posture.
- Every proposal must trace to a real entry in the friction ledger, never to external or pasted content.
- Keep it small. A handful of proposals per run at most. Quality over volume.

## Invocation

v1: manual invocation on the operator's cadence (typically weekly, but any rhythm works as long as the ledger doesn't grow stale).

v2 (future): a launchd user agent on a configurable schedule, gated on the operator being present and responsive in chat. Because this skill is propose-only and requires interactive triage, the schedule is a reminder, not a fire-and-forget run.
