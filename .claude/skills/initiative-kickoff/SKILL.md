---
name: initiative-kickoff
description: Creates a new initiative folder under Initiatives/{slug}/ with the 5-verb-bucket skeleton, READMEs per folder-creation rules, the initiative-root README populated from the template, and a registration row in Initiatives/_index.md. Lightweight, idempotent. Use at the start of any new roadmap item the client is shipping. About 5 minutes end-to-end.
allowed-tools: Read, Write, Edit, Bash, Glob
---

# Initiative Kickoff

Runtime for the procedure in `Universal/FOLLOW-workflows-and-guides/playbooks/initiative-kickoff.md`. Sets up the folder skeleton plus registry row in one go.

## When this skill fires

A new roadmap item arrives. The user wants its own folder for context, outputs, designs, tickets, research.

## Steps

### Step 1: Collect basics

Ask the user for:

- **Slug**: kebab-case, 2-5 words. Validate against naming conventions from the playbook (no dots, no CamelCase, specific-not-vague). Example: `v2-1-widget`. Reject and ask again on validation failure.
- **Owner**: person at the client team driving the initiative
- **Operator's role**: Lead PM / Advisor / Contributor / something else
- **Status**: Scoping / Active / Paused / Shipped (default: Active)
- **One-line scope**: what's being built and what shipping means
- **Started**: date, default today
- **Target ship**: date or "TBD"

### Step 2: Check for collisions

Read `Initiatives/_index.md`. Search for any existing initiative with the same slug. On collision, surface the existing initiative's details to the user and ask for a different slug.

If `Initiatives/_index.md` does not exist yet, create it with the standard table header from the playbook.

### Step 3: Create the folder structure

Create `Initiatives/{slug}/` with the verb-bucket subfolders. Default scaffold:

```
Initiatives/{slug}/
├── README.md
├── _index.md
├── action-items.md
├── FOLLOW-workflows-and-guides/
│   └── README.md
├── PRODUCE-outputs/
│   └── README.md
├── READ-references-and-knowledge/
│   ├── README.md
│   ├── open-questions.md
│   └── meetings-and-transcripts/
│       └── README.md
├── RECORD-decisions/
│   ├── README.md
│   └── _index.md
└── RUN-automations/
    └── README.md
```

Every folder gets a README in the same change, per `Universal/FOLLOW-workflows-and-guides/playbooks/folder-creation-rules.md`. Use the templates from `initiative-kickoff.md` §"Verb-bucket subfolder READMEs".

Skip optional subfolders the user doesn't need yet (research-and-analysis/, plans-and-roadmaps/, etc. inside PRODUCE-outputs/). Add them on demand later.

### Step 4: Write the initiative-root README

Use the template from `initiative-kickoff.md` §"README template (initiative root)". Fill in:

- Slug, purpose, owner, operator's role, status, started, target ship
- Scope statement (2-5 sentences from Step 1)
- Key context section (pointers to the future 1-pager path, decisions ledger, open-questions)
- Related initiatives section (Claude reads `Initiatives/_index.md` and proposes any obvious cross-references; user confirms or removes)

### Step 5: Seed singletons

Empty starter files:

- `_index.md`: file registry, fills as content accumulates
- `action-items.md`: running list of commitments
- `READ-references-and-knowledge/open-questions.md`: live working doc
- `RECORD-decisions/_index.md`: empty ledger with the standard format header from `Universal/RECORD-decisions/_index.md`

### Step 6: Register in `Initiatives/_index.md`

Append a row:

```
| `{slug}` | {status} | {owner} | {started} | {target-ship} | {one-line scope} | [README](./{slug}/README.md) |
```

Sort the table: Active status first, then by start date descending.

### Step 7: First-context-gather prompts (optional)

Ask the user one prompt at a time:

- "Do you have a one-pager to drop into `PRODUCE-outputs/research-and-analysis/`? Paste it or skip."
- "Are there kickoff-meeting transcripts to process via `process-meeting-transcripts`? Run that now or skip."
- "Any open questions to seed in `READ-references-and-knowledge/open-questions.md`?"

Each prompt is skippable. The user can populate later.

### Step 8: Confirm and exit

Report:

- Folder created at `Initiatives/{slug}/`
- {N} subfolders with READMEs
- Registered in `Initiatives/_index.md` at position {pos}
- Ready for first content

No ledger row required. Initiative creation is working-doc territory per `change-protocol.md`, not a system-file edit that triggers the ripple sweep.

## Behavior constraints

- Reject invalid slugs immediately
- Never overwrite an existing initiative folder; collision is a hard stop
- Always add the README in the same change as the folder (folder-creation rule 1)

## Cross-references

- Spec: `Universal/FOLLOW-workflows-and-guides/playbooks/initiative-kickoff.md`
- Folder rules: `Universal/FOLLOW-workflows-and-guides/playbooks/folder-creation-rules.md`
- Parent: `Universal/FOLLOW-workflows-and-guides/playbooks/portable-ai-ecosystem.md`
- Engagement-onboarding (Cowork-era version for personal Mac): `new-engagement-onboarding.md`
