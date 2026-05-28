---
name: change-protocol-sweep
description: Automates the 6-step doc-sync ripple sweep from change-protocol.md when a system file has been edited. Builds the alias set, runs greps, checks the three registries, applies the structural co-vary table, recurses, and surfaces a tagged checklist (must-edit / review / structural) for the operator to action. Writes a one-line entry to the decisions ledger on completion. Use after any edit to a rule file, playbook, skill, voice file, hook, or README that other docs reference.
allowed-tools: Read, Write, Edit, Bash, Glob, Grep
---

# Change Protocol Sweep

Runtime for the 6-step ripple sweep defined in `Universal/FOLLOW-workflows-and-guides/playbooks/change-protocol.md`. The playbook is the spec; this skill is the runtime that walks the procedure.

## When this skill fires

The operator just edited a system file and wants the doc-sync sweep run before closing the session. System-file categories: rule files (AGENTS.md, CLAUDE.md), playbooks, skills, voice files, hooks, concept docs, `_index.md` registries, READMEs, scheduled tasks, folder-structure changes.

## When NOT to fire

- Working-file edits (research docs, handoffs, action-items, transcripts, drafts) do not trigger the sweep.
- Mechanical edits (typo fixes that don't change meaning, skill version bumps) can use a one-line sweep.
- Editing the change-protocol playbook itself: handle separately (this skill can sweep its own edits but the operator may want to verify manually).

## Steps

### Step 1: Name X and build the alias set

Ask the operator: what changed? Capture in one sentence.

Build the alias set:
- Canonical name (the official label)
- Path basename
- Any prior names (renames leave a long tail)
- Common abbreviations
- The behavior phrase people use instead of the name

If the operator can supply the alias set directly, accept it. Otherwise, propose one based on the changed file's content and ask for confirmation.

### Step 2: Grep every alias across the repo

For each alias, run:

```bash
grep -rln -e '{alias}' . --include="*.md" --include="*.sh" --include="*.json" --include="*.yaml" 2>/dev/null | grep -v "_trash/" | sort
```

Collect all matching files into the candidate set.

### Step 3: Check the three registries

Check whether X is registered in:
- `RUN-automations/skills/_index.md` (skills registry, if it exists in the repo)
- `.claude/skills/` directory listing (active skills)
- `Initiatives/_index.md` (initiatives registry)
- Any other registry the repo has at the root level

If X has a row in any registry, add the registry file to the candidate set with tag `structural`.

### Step 4: Add structural co-vary neighbors

Some files always change together by rule. Apply this table:

| Edit type | Always co-vary neighbors |
|---|---|
| Skill change | The skill's own CHANGELOG.md (if it exists), the `.claude/skills/` listing, any playbook that references the skill |
| AGENTS.md or CLAUDE.md change | The byte-identical sibling (same level), the relevant playbook that defines the rule being changed |
| Hook change | `.claude/settings.json.template`, INSTALL.md if the hook's invocation is documented there, the playbook that describes the hook behavior |
| Playbook change | The playbooks README/_index, any skill that loads the playbook at runtime, the change-protocol's own structural neighbor list if the playbook itself is change-protocol |
| Voice file change | `voice-composition.md` (which references the layer files), the voice/README.md |
| Folder structure change (new folder, rename, move) | The folder's new README.md (per folder-creation rules), the parent's _index.md if applicable, any docs that reference the old path |

Add the co-vary files to the candidate set with tag `structural`.

### Step 5: Semantic / conceptual search

For each alias, run a conceptual grep that catches docs describing X's behavior without naming X. Use the operator's intuition for what concepts X embodies. Examples:

- If X is a skill, search for the workflow it implements
- If X is a playbook, search for the concept it documents
- If X is a hook, search for the lifecycle event it handles

This is judgment-based, not mechanical. Surface candidates to the operator with rationale; the operator confirms or rejects each.

### Step 6: Recurse one level, dedupe, tag

For each document the sweep identified as a candidate, ask: does anything in the repo describe THIS document? If yes, those second-order documents also drift. Add them.

Then dedupe and tag each entry:
- **must-edit**: the stale fact is wrong as written; fix it
- **review**: the document mentions X but may already be correct; read and decide
- **structural**: a row, count, version, or table cell that needs a mechanical update

Surface the full checklist to the operator before edits start.

## Apply edits

For each `must-edit` entry, edit the file. For each `structural` entry, apply the mechanical change. For each `review` entry, surface the file to the operator and ask for the disposition (edit / skip-clean / ledger-note).

After edits, run a verification grep: any remaining alias matches in files NOT on the checklist? If yes, surface them; the operator decides whether they're in scope.

## Ledger entry

On completion, append one row to `Universal/RECORD-decisions/_index.md`:

```
| {YYYY-MM-DD} | {Decision sentence}. Sweep touched {N} files: {list of paths or count}. | Universal | change-protocol-sweep skill | (rationale in this ledger row or {link to detail doc if non-obvious}) |
```

For Tier 1 changes (rule files, hooks, memory architecture), additionally invoke the fresh-eyes verification subagent per `change-protocol.md` §"Verification subagent contract". This skill does not run the subagent inline; the operator does, since it requires reading the sweep's full output context.

## Behavior constraints

- Never edit files outside the sweep's checklist without surfacing them first
- Never mark a `review` entry as `must-edit` without operator confirmation
- Never skip the ledger entry on a Tier 1 change
- The sweep is conservative: when in doubt, surface, don't assume

## Failure handling

- If grep returns zero hits for all aliases: surface "the changed thing has no documented references." This is unusual; verify the alias set covers all names X is known by.
- If a registry file is missing: surface as a structural gap; the operator decides whether to create it or note the absence.
- If the operator can't decide on a `review` entry: tag as `ESCALATE` and continue; surface at end for batch decision.

## Cross-references

- Spec: `Universal/FOLLOW-workflows-and-guides/playbooks/change-protocol.md`
- Ledger format: same playbook §"Decisions ledger interaction"
- Tier classification: same playbook §"Verification tiers"
- Folder-creation rules (for structural folder changes): `Universal/FOLLOW-workflows-and-guides/playbooks/folder-creation-rules.md`
