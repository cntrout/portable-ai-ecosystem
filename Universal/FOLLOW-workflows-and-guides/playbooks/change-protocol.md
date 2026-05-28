---
type: playbook
last_reviewed: 2026-05-27
sync_trigger: 2026-05-27-portable-ai-ecosystem-pre-staging
depends-on:
  - playbook:folder-creation-rules
---

# Documentation Sync Change Protocol

## TL;DR

A system-file edit triggers a ripple sweep that updates every document
describing the changed thing. The sweep splits into two phases: tight-couple
updates fire inline (the AGENTS to CLAUDE mirror, a skill's own CHANGELOG),
and the wider sweep batches at end of work. At natural conversation endings
or pivots, Claude prompts the user for batch approval rather than waiting
to be asked. Tier 1 foundational changes (rule files, memory architecture,
hooks) get a fresh-eyes verification subagent as a final gate; Tier 2
changes rely on the nightly README-coverage backstop where the
workspace-health-check skill is installed.

Every completed sweep appends one row to `Universal/RECORD-decisions/_index.md` and
stamps `sync_trigger:` frontmatter on touched files. Working-file edits
(research docs, handoffs, 1-pagers, invoices, transcripts) do not fire the
sweep.

## Trigger scope

Two categories. System files fire the protocol. Working files do not.

### System files (sweep fires)

Any edit to one of these triggers the change-protocol procedure:

- Rule files: root `CLAUDE.md`/`AGENTS.md`, `Universal/CLAUDE.md`/`AGENTS.md`,
  initiative-level `CLAUDE.md`/`AGENTS.md`, and initiative `READ-references-and-knowledge/` plus `FOLLOW-workflows-and-guides/` docs
- Skills (anything under `RUN-automations/skills/`)
- Plugins (anything under `RUN-automations/Plugins/`)
- Playbooks (`Universal/FOLLOW-workflows-and-guides/playbooks/`)
- Concept docs (`Universal/READ-references-and-knowledge/concepts/`)
- Hooks (`.claude/hooks/`)
- Memory architecture (`Universal/READ-references-and-knowledge/memory/` and `Initiatives/{slug}/READ-references-and-knowledge/memory/`)
- `Universal/tools.md`
- Architecture diagrams (`Universal/PRODUCE-outputs/assets/diagrams/`)
- `_index.md` files
- `README.md` files
- Brand/voice files (`Universal/FOLLOW-workflows-and-guides/voice/`)
- Live artifacts (`Universal/PRODUCE-outputs/artifacts/`)
- Scheduled tasks (`Scheduled/`)
- Folder structure changes (new folder created, folder moved, folder renamed)

### Working files (no sweep)

These edit without triggering anything:

- 1-pagers, opportunity proposals, analyses
- Glossary entries (`Universal/READ-references-and-knowledge/glossary/`)
- Invoices
- Research docs (`Universal/PRODUCE-outputs/research/`)
- Handoffs (`Universal/PRODUCE-outputs/handoffs/`)
- Frameworks (`Universal/READ-references-and-knowledge/frameworks/`)
- Entity pages (`Universal/READ-references-and-knowledge/entities/`)
- Meeting transcripts and notes
- Watch-run outputs (`Scheduled/{task-slug}/runs/`)
- Working content inside initiative folders (anything that isn't
  `CLAUDE.md`/`AGENTS.md`/`Reference/`)

If a working-file edit ever needs a sweep, the user just asks. The default is
no-trigger for working files because they describe singular work products
rather than the system itself.

## The six-step ripple sweep

Run these in order. The output of step 6 is the work checklist for the edit.
The verification subagent (Tier 1 only) re-derives this same checklist
independently and diffs against it.

### Step 1: name X and build the alias set

Name the changed thing precisely. Then build its alias set: the canonical
name, the path basename, any prior names (a rename leaves a long tail under
the old name), abbreviations, and the behavior phrase people use instead of
the name.

*Example.* Decommissioning a hypothetical `legacy-search` MCP server needs the alias set:
`legacy-search`, `legacy-search-mcp`, `claude-legacy-search`, `keyword index` (prior
layer designation), `Lucene` (the underlying store), and `legacy-search's file
watcher`. Without the alias set, a grep on `legacy-search` alone misses files
that describe it as "the keyword index" or "the file watcher."

### Step 2: grep every alias across the vault

Run a literal grep for every alias from step 1. This catches the bulk of
references, which are bare-text mentions rather than wikilinks. A typical
vault has hundreds of bare-text references across hundreds of files, so
link-graph traversal misses most dependencies. Grep is the backbone.

Filter out `_trash/` and `Scheduled/.../runs/` (working-file territory) unless the
changed thing is itself in that scope.

*Example.* `grep -rln -e "legacy-search" -e "keyword-index" . --include="*.md" | grep -v "_trash/" | grep -v "Scheduled/{task-slug}/runs/" | sort`
returns the bare-text reference set for the legacy-search decommission.

### Step 3: check the three `_index.md` registries

Check whether X is registered in one of the three top-level registries:

- `RUN-automations/skills/_index.md`, skills registry
- `RUN-automations/Plugins/_index.md`, plugins registry
- `Initiatives/_index.md`, engagements registry

If X has a row in any of them, that row needs editing. If X is being
introduced or retired, that's an add or remove operation, not just an edit.

*Example.* Decommissioning `legacy-search` means removing the `legacy-search` row
from `RUN-automations/Plugins/_index.md` (or marking it decommissioned), even if no other
file mentioned it directly.

### Step 4: add structural neighbors that co-vary by rule

Some files always change together by rule, even when they do not name X. Add
them to the checklist by the rule, not by grep:

| Edit type | Always-co-vary neighbors |
|---|---|
| Skill change | `RUN-automations/skills/_index.md` row, `RUN-automations/skills/CHANGELOG.md`, `RUN-automations/Plugins/_index.md` version, the architecture diagram |
| `workspace-health-check` pass change | `SKILL.md` pass table and count, `references/cadence-and-tiers.md`, `pass-dependency-graph.md`, sibling pass specs that cite it |
| CLAUDE.md/AGENTS.md rule change | byte-identical sibling, `Universal/` copies if promoted, the relevant pass specs, `maintenance-schedule.md` watch-conditions |
| Session-start hook change | `.claude/settings.json`, session-start pass spec, `automation-schedule.md`, `verify-ecosystem-health.md`, the architecture diagram |
| MCP / tool change | `Universal/tools.md`, MCP-touch pass spec, `RUN-automations/Plugins/_index.md`, `concepts/local-mcp-servers.md`, relevant `activate-*.md` playbook |
| Memory architecture change | `Universal/AGENTS.md`/`CLAUDE.md`, `tools.md`, the relevant playbooks and concept docs, `memory/` READMEs, recent handoffs |

*Example.* A new pass added to `workspace-health-check` updates the SKILL.md
pass count even if the SKILL.md does not mention the new pass by number. The
pass-table row is the always-co-vary neighbor.

### Step 5: run semantic search for the concept

Run a `search_by_text` query via the `smart-connections` MCP tool for the
*concept* X embodies, not just its name. This catches documents that
describe X's behavior without naming X. Treat the results as candidates to
judge, not a closed set.

*Example.* For the legacy-search decommission, semantic search on "keyword
index," "full-text search backend," and "search architecture" surfaces docs
that frame legacy-search's role without using the word "legacy-search."

### Step 6: recurse one level on describing documents, then deduplicate

For each document that *describes* X (rather than merely mentioning it in
passing), check whether anything references the description. Those
second-order documents also drift.

Then dedupe everything from steps 2 to 6 into one checklist. Tag each entry:

- **must-edit**, the stale fact is wrong as written; fix it
- **review**, the document mentions X but may already be correct; read and
  decide
- **structural**, a row, count, version, or table cell that needs a
  mechanical update

The checklist is what the edit session runs against. For Tier 1 changes the
verification subagent re-derives it independently and diffs.

## Inline vs batch timing

Two phases of update with different timing.

### Inline updates (fire at the moment of the edit)

These are atomic with the source edit. They never wait:

- AGENTS.md to CLAUDE.md byte-identical mirror at any path
- A skill's own `CHANGELOG.md` update for any change under `RUN-automations/skills/{skill}/`

These rules already exist in `AGENTS.md`'s "Edit-time sync rules" section
and have a perfect compliance record. The change protocol does not modify
them; it sits next to them and handles the wider ripple.

### Batch ripple (queues, flushes at end of work)

Steps 2 to 6 of the sweep run as a batch at the close of the work session. The
reason for batching: if a single conceptual change touches 12 files, doing
the full sweep after every individual edit thrashes the conversation and
produces partial states. Holding the sweep until the conceptual unit of
work is done lets the checklist be derived once and run once.

Claude prompts the user for batch approval whenever the conversation reaches a
natural ending or pivot. The prompt template:

> System-file edits in this session: [list]. Running the change-protocol
> sweep against them now. Estimated affected files: [count]. Proceed?

The user approves, defers, or asks for a different scope. The prompt removes
the requirement that the user remember to trigger the flush.

If a session drops before the prompt fires, the nightly README-coverage backstop
(when installed) catches the missed sweep the next morning.
Until the backstop ships, a missed sweep surfaces during the next manual touch
of an affected file or during a `workspace-health-check` run that hits the
stale claim by another route.

## Verification tiers

Tiered to match verification cost against change stakes. The tier of the
change, not the editor's intuition, determines whether the inline subagent
runs.

### Tier 1 (inline subagent verification)

Changes to these files run the verification subagent as the last step of
the sweep:

- Rule files: `CLAUDE.md`/`AGENTS.md` at any level
- Memory architecture: anything under `Universal/READ-references-and-knowledge/memory/` or
  `Initiatives/{slug}/READ-references-and-knowledge/memory/`
- Hooks: anything under `.claude/hooks/`

These are the files that govern the rest of the system. A stale rule file
produces follow-on drift across every session that reads it. The inline
verification pass earns its cost on these.

### Tier 2 (sweep only, no inline verification)

Every other system-file category: skills, plugins, playbooks, concept docs,
indexes, READMEs, voice files, live artifacts, scheduled tasks, folder
structure changes, `tools.md`, architecture diagrams, `Reference/` docs.

These still get the full six-step sweep. They skip the inline subagent
because the cost of running it on every README tweak exceeds its expected
value. Tier 2 drift is caught by the nightly README-coverage backstop where
the workspace-health-check skill is installed.

## Verification subagent contract

Runs only on Tier 1 changes. Independent of the editor.

### What it does

Given only the input "X changed":

1. Re-derives the affected-file list independently from scratch, following
   steps 1 to 6 of the sweep.
2. Diffs its derived list against the editor's checklist. Any file the
   subagent found that the editor missed is a gap.
3. Re-reads each file the editor edited and confirms the stale fact is gone,
   not just that the file was touched. This catches the superficial-edit
   failure mode: a file modified to satisfy the checklist without actually
   correcting the stale claim.
4. Cross-checks against the dependency manifest: any file with
   `depends-on: X` in its frontmatter that was not on the editor's checklist
   is also a gap.

### What it returns

A pass or fail with a gap list, in the same shape as health-check triage:

- **Pass**, no gaps. Sweep is complete.
- **Fail (gaps)**, list of files the editor missed or files where the
  stale fact survived the edit. Each entry includes the file path, the gap
  type (missed-file or surviving-stale-fact), and the specific fact that
  should have changed.

The main session reviews the gap list and either closes each gap or
explicitly accepts it with a one-line rationale recorded in the ledger row.

### Subagent invocation template

When the editor's batch sweep includes a Tier 1 change, invoke the
verification subagent via the Agent tool with `general-purpose` as the
subagent type. Prompt template:

> You are the fresh-eyes verification subagent for a documentation sweep
> that just completed in the user's Obsidian vault at `{vault-root}`.
> Your job: re-derive the affected-file list independently and verify
> that the editor actually flipped the stale claims, not just touched
> the files.
>
> **What changed:** {one to three sentences describing the change in
> concrete terms, canonical name, dated decommission events, supersession
> links, and what replaces what}.
>
> **Your job, in order.**
>
> 1. *Re-derive the affected-file list.* Follow steps 1 to 6 of
>    `Universal/FOLLOW-workflows-and-guides/playbooks/change-protocol.md`'s ripple sweep. Tag each
>    file as must-edit, review, structural, or skip-historical.
> 2. *Produce the editor's actual list.* Discover it; do not ask. Compare
>    modification times against the conversation timestamp range, or
>    re-grep for the new replacement strings the editor would have used.
> 3. *Gap analysis.* Diff your re-derived list against the editor's
>    actual set. Identify missed files, surviving stale facts, and any
>    out-of-scope edits.
> 4. *Re-read each edited file* and confirm the stale fact is actually
>    gone, not just that the file was touched.
>
> **Return format.** Status (PASS or FAIL); independently-derived
> affected set; editor's actual edited set; gaps (missed-file,
> surviving-stale-fact, out-of-scope); spot-check per Tier 1 file with a
> quote of the new wording; recommendation.
>
> Be ruthless. The editor's blind spot is assuming wider edits propagated
> correctly. Re-discover from scratch; the value of your pass is in
> catching what the editor missed.

The brief is intentionally narrow. Do not pass the editor's checklist to
the subagent at the start; the independent re-derivation is the value-add.

### Integration with the editing session

The subagent returns its report to the main session. The main session
then:

1. **PASS:** the sweep is complete. Append the ledger row, move on.
2. **FAIL with gaps:** for each gap, either close it (edit the missed
   file, deepen the surviving-stale-fact correction) or explicitly accept
   it with a one-line rationale recorded in the ledger row's notes
   column. Re-run the subagent only if a gap closure introduces
   substantial new edits; small fixes do not warrant a re-run.

The first real Tier 1 verification exercise (a previous architecture rethink
that decommissioned a search-and-memory subsystem) caught two genuine gaps:
an untouched playbook the editor had deferred, plus a surviving sibling
reference in the same file as a successful edit. Both were closed before
completion. That run becomes the calibration reference for future Tier 1
verifications.

### Tool budget

A typical Tier 1 verification runs 10 to 25 tool calls (grep, mtime checks,
file Reads, optional semantic search) and completes in 90 to 180 seconds.
Budget 1500 to 4000 tokens for the prompt plus return.

### Why fresh eyes

The editor knows what they meant to change. That knowledge is also the
editor's blind spot: the editor assumes the wider system reflects the new
state because they already updated the files they were thinking about. A
subagent that only knows "X changed" and nothing else cannot inherit that
assumption. It re-discovers the affected set without the editor's mental
model.

## Decisions ledger interaction

Every completed sweep writes to the ledger. The ledger is the system's audit
trail and the cross-reference target for `sync_trigger:` frontmatter.

### Append one row per sweep

On sweep completion, append a row to `Universal/RECORD-decisions/_index.md` (or
the initiative mirror at `Initiatives/{slug}/RECORD-decisions/_index.md` if the change
is initiative-scoped):

| Date | Decision | Scope | Triggered by | Record |
|------|----------|-------|--------------|--------|
| YYYY-MM-DD | One-sentence statement of the change | universal / initiative slug | The originating action (research doc, handoff, session, incident) | Link to detail doc if rationale is non-obvious; otherwise blank |

If the change has rationale worth preserving, write a dated ADR-style file
at `Universal/RECORD-decisions/YYYY-MM-DD - {slug}.md` and link it in the Record
column. If the change is mechanical (a skill version bump, a typo fix), no
ADR is needed and the Record column stays blank.

### Stamp `sync_trigger:` on touched files

Every file the sweep touched gets a `sync_trigger:` frontmatter field
pointing at the ledger row:

```yaml
---
type: playbook
last_reviewed: YYYY-MM-DD
sync_trigger: YYYY-MM-DD-{slug}
---
```

The slug is the ledger row's slug (date plus identifier). A reader can
trace from any touched file back to the originating decision, and from the
decision row forward to every file it changed.

**Files without existing frontmatter.** Some system files intentionally
have no YAML frontmatter (root rule files, most `README.md` files, a few
indexes). The sweep does not add frontmatter to those files just to record
a sync trigger; that would be a structural change the file's authors
deliberately avoided. For these files, the audit trail relies on the
ledger row alone. If a sweep needs to record exactly which files it
touched (for example, for high-stakes Tier 1 changes), write a dated ADR-style
file under `Universal/RECORD-decisions/YYYY-MM-DD - {slug}.md` and list the
touched files there.

### Why one row per sweep, not one row per file

The ledger is a decisions log, not an edits log. Per-file granularity
belongs in machine-written logs (`.health-check/` JSON, git history if it
existed for the vault). The ledger answers "what foundational changes have
I shipped in the last quarter," at a granularity a human can read.

### Coordination with sibling memory-compilation pipelines

`Universal/RECORD-decisions/` is shared infrastructure with any sibling
memory-compilation task that also appends decisions (see the relevant
architecture-rethink research doc for details). Both this protocol and
any sibling compiler append to the same ledger, partition-respecting
(`Universal/RECORD-decisions/` for ecosystem-wide,
`Initiatives/{slug}/RECORD-decisions/` for initiative-specific). Whichever build ships
its Phase 1 first creates the folder; the other integrates.

## Bootstrap exception

The first run of this playbook is its own first row in the ledger. The
protocol does not run the protocol on the work that built the protocol,
because the protocol does not exist until the build completes. The first
real cleanup task after the build (for example, a legacy-tool decommission
sweep) is the first real exercise; it earns the second ledger row, with
this playbook as its trigger.

## Related

- `Universal/RECORD-decisions/_index.md`, the ledger this playbook writes to
- `Universal/FOLLOW-workflows-and-guides/playbooks/maintenance-schedule.md`, the manual cadence backstop
- `Universal/FOLLOW-workflows-and-guides/playbooks/automation-schedule.md`, where the README-coverage backstop lives once the workspace-health-check skill is installed
- `RUN-automations/skills/workspace-health-check/SKILL.md`, the deterministic backstop for missed sweeps
- Root plus Universal `AGENTS.md`/`CLAUDE.md` "Edit-time sync rules", the rule that points here

*History: [Universal/RECORD-decisions/_index.md](../../RECORD-decisions/_index.md)*
