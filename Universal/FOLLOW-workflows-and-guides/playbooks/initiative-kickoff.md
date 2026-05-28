---
type: playbook
last_reviewed: 2026-05-27
sync_trigger: 2026-05-27-deferred-items-batch
depends-on:
  - playbook:portable-ai-ecosystem
  - playbook:engagement-bootstrap-from-urls
  - playbook:folder-creation-rules
  - playbook:change-protocol
---

# Initiative Kickoff Playbook

Spin up a new initiative folder under `Initiatives/{slug}/` on the soft-partition client device. Lightweight sibling to `engagement-bootstrap-from-urls.md`: that playbook bootstraps a whole engagement; this one bootstraps a single roadmap item *within* an engagement.

Initiatives are the unit of work the client ships. Common examples: a feature build, a rename or migration experiment, a partner integration onboarding.

## TL;DR

Pick a slug. Create `Initiatives/{slug}/` with the 5 verb-bucket subfolders, each with a README. Drop a top-level `README.md` describing the initiative. Add a row to `Initiatives/_index.md`. Done in ~5 minutes. Initiative inherits root + engagement-layer context automatically. AGENTS.md / CLAUDE.md only get created if the initiative needs distinct rules, which is rare.

**No change-protocol sweep fires for initiative creation.** Creating a new initiative folder is working-doc territory: the skeleton comes from `Initiatives/_template/`, no system files need updating elsewhere, and the registry update to `Initiatives/_index.md` happens inline as part of the creation. The sweep fires only on later events such as promoting an initiative artifact to `Universal/` or editing initiative-level AGENTS.md / CLAUDE.md.

## When to run this

- A new roadmap item arrives and you'll be doing dedicated work on it
- An existing workstream has accumulated enough context to deserve its own folder
- A short-lived experiment is large enough to keep separate from cross-cutting notes

**When NOT to run this:**

- One-off tasks under a day. Use cross-cutting notes
- Anything that belongs at the engagement level (cross-initiative patterns, glossary additions, decisions affecting multiple initiatives)
- A meeting series that doesn't have its own deliverable. File transcripts at the engagement level

## Pre-kickoff checklist

Before creating the folder:

- [ ] You know the initiative's name, owner, and one-line scope
- [ ] You've checked `Initiatives/_index.md` to confirm no existing initiative covers it
- [ ] You've decided whether the initiative is active or just being scoped (active gets `Initiatives/{slug}/`; scoping-only stays at engagement level until it activates)
- [ ] You have a slug in mind (see naming below)

## Naming conventions

Slugs are kebab-case. Aim for 2-5 words. Specific enough that the slug names what's being built, generic enough that the operator can decode it without context months later.

Good:
- `v2-1-widget`
- `payment-method-rename-experiment`
- `partner-integration-onboarding`
- `q3-pricing-test`

Avoid:
- `widget` (too vague)
- `the-big-thing` (no information)
- `widget-v2.1` (use dashes, not dots)
- `WidgetV21` (kebab-case, not CamelCase)

If two initiatives have similar names, append a year or quarter: `widget-v2-1` vs `widget-v2-1-q3-pricing-test`.

## Folder structure

Every initiative mirrors the 5-verb-bucket structure used at Universal and per-engagement levels. This keeps the mental model consistent.

```
Initiatives/{slug}/
├── README.md                              (initiative overview, scope, owner, status)
├── _index.md                              (file registry, fills as content accumulates)
├── action-items.md                        (initiative-scoped action items, live working doc)
│
├── FOLLOW-workflows-and-guides/           (rules specific to this initiative, optional)
│   └── README.md
│
├── PRODUCE-outputs/                       (deliverables produced for this initiative)
│   ├── README.md
│   ├── research-and-analysis/             (deep dives, competitive scans, evidence)
│   ├── plans-and-roadmaps/                (the active plan for this initiative)
│   ├── tickets/                           (if relevant; post-its-to-tickets output)
│   ├── handoffs/                          (initiative-scoped cross-session bridges)
│   ├── assets/                            (screenshots, exports, reports)
│   └── artifacts/                         (live HTML if relevant; placeholder otherwise)
│
├── READ-references-and-knowledge/         (initiative-scoped knowledge base)
│   ├── README.md
│   ├── open-questions.md                  (live working doc)
│   ├── meetings-and-transcripts/          (process-meeting-transcripts files here)
│   └── product-knowledge/                 (initiative-specific product context, if any)
│
├── RECORD-decisions/                      (initiative-scoped decisions ledger)
│   ├── README.md
│   └── _index.md                          (same format as Universal ledger)
│
└── RUN-automations/                       (forward-looking placeholder)
    └── README.md
```

Subfolders are optional except `PRODUCE-outputs/` and `READ-references-and-knowledge/` (which most initiatives need). Skip the rest if there's no current content for them. The folder-creation rules apply: every folder you DO create needs a README in the same change.

## README template (initiative root)

```markdown
# Initiatives/{slug}/

**Purpose:** {One sentence: what's being built and what shipping means.}

**Owner:** {Person at the client team driving the initiative.}

**Operator's role:** {Lead PM / Advisor / Contributor / etc.}

**Status:** {Scoping / Active / Paused / Shipped / Archived}

**Started:** {YYYY-MM-DD}

**Target ship:** {YYYY-MM-DD or "TBD"}

**Structure mirrors `Universal/`:** same 5 verb-buckets (FOLLOW / PRODUCE / READ / RECORD / RUN), initiative-scoped.

**Soft partition:** when pwd is inside this folder, context defaults to this initiative + engagement layer + Universal/. Cross-initiative reads are permitted but writes default here.

## Scope

{2-5 sentences on what's in scope and what's explicitly out of scope. Borrow from a 1-pager if one exists.}

## Key context

- One-pager: `PRODUCE-outputs/research-and-analysis/{slug}-one-pager.md` (if exists)
- Active plan: `PRODUCE-outputs/plans-and-roadmaps/{slug}-plan.md` (if exists)
- Decisions ledger: `RECORD-decisions/_index.md`
- Open questions: `READ-references-and-knowledge/open-questions.md`

## Related initiatives

- {slug-of-related-initiative}: {how they relate}
```

Adjust to fit. The "Related initiatives" section is the soft-partition feature in action: explicitly call out other initiatives this one references.

## Verb-bucket subfolder READMEs

Use these compact READMEs for each subfolder you create. The folder-creation rules require a README in the same change as the folder.

### `FOLLOW-workflows-and-guides/README.md`

```markdown
# Initiatives/{slug}/FOLLOW-workflows-and-guides/

**Purpose:** Rules specific to this initiative. Most initiatives inherit from engagement-level + Universal; this folder exists only when the initiative has unique conventions worth documenting.

Empty until needed.
```

### `PRODUCE-outputs/README.md`

```markdown
# Initiatives/{slug}/PRODUCE-outputs/

**Purpose:** Deliverables and session outputs for this initiative.

**Subfolders:** research-and-analysis (deep dives), plans-and-roadmaps (the active plan), tickets (post-its-to-tickets output if relevant), handoffs (cross-session bridges), assets (screenshots, exports), artifacts (live HTML if relevant).
```

### `READ-references-and-knowledge/README.md`

```markdown
# Initiatives/{slug}/READ-references-and-knowledge/

**Purpose:** Initiative-scoped knowledge base. Meetings, open questions, product reference.

**Subfolders:** meetings-and-transcripts (transcript files via `process-meeting-transcripts.md`), product-knowledge (initiative-specific product context).

**Singletons:** open-questions.md (live working doc).
```

### `RECORD-decisions/README.md`

```markdown
# Initiatives/{slug}/RECORD-decisions/

**Purpose:** Initiative-scoped decisions ledger. Same format as the Universal ledger.

**Lifecycle:** append-only. Annual rotation if it grows beyond one screen.

See `_index.md` for the ledger and `Universal/FOLLOW-workflows-and-guides/playbooks/change-protocol.md` for the row format.
```

### `RUN-automations/README.md`

```markdown
# Initiatives/{slug}/RUN-automations/

**Purpose:** Initiative-specific automation. Forward-looking placeholder; most automation lives at vault root.
```

## Update `Initiatives/_index.md`

After creating the folder, add a row to the registry. Format:

| Slug | Status | Owner | Started | Target ship | One-line scope | Link |
|---|---|---|---|---|---|---|
| `{slug}` | Scoping / Active / Paused | {name} | YYYY-MM-DD | YYYY-MM-DD or TBD | {1 sentence} | [README](./{slug}/README.md) |

Sort by status (Active first), then by start date descending.

## First context gather

Once the folder exists, seed it with starting context:

- [ ] Copy the one-pager (if one exists) into `PRODUCE-outputs/research-and-analysis/{slug}-one-pager.md`
- [ ] Seed `READ-references-and-knowledge/open-questions.md` with anything unresolved you already know about
- [ ] If there are kickoff-meeting transcripts, file them via `process-meeting-transcripts.md`
- [ ] Add the initiative slug to any cross-initiative pattern docs that should reference it (e.g., `transcript-classification-rules.md` if relevant)

## When to consider AGENTS.md / CLAUDE.md for an initiative

Rare. The initiative inherits from root and engagement-layer rule cascades. Create initiative-level AGENTS.md / CLAUDE.md only when:

- The initiative has a partner / customer who reads its docs and needs a distinct voice (Layer 3 override)
- The initiative has unique terminology that would clutter the engagement glossary if added globally
- The initiative has a different workflow (e.g., a customer-facing experiment with regulatory requirements engagement-wide work doesn't need)

When you do create AGENTS.md / CLAUDE.md for an initiative, the atomic byte-identical rule applies. Keep both files in sync per `change-protocol.md` "Edit-time sync rules".

## Lifecycle

| Phase | Folder location |
|---|---|
| Scoping (not yet committed) | Engagement-level notes; no folder yet |
| Active | `Initiatives/{slug}/` |
| Paused | `Initiatives/{slug}/` with README status flipped to "Paused" |
| Shipped | `Initiatives/{slug}/` with README status flipped to "Shipped"; folder stays put for ~30 days as a reference, then move |
| Archived | `Initiatives/_archived/{slug}/` (per folder-creation-rules exemption for `_archived/` subfolders) |

The 30-day post-ship window is so other initiatives can still reference the shipped initiative's decisions and research without crossing into the archive. After 30 days, move to `_archived/` and update `Initiatives/_index.md`.

## Promotion (initiative → Universal)

When an initiative-scoped artifact turns out to be reusable across initiatives or engagements, promote it to Universal. Examples:

- A 1-pager template you wrote for this initiative is the cleanest version yet. Promote to `Universal/FOLLOW-workflows-and-guides/templates/` or `Universal/PRODUCE-outputs/exemplars/`
- A research-synthesis approach worked well. Promote the playbook (the rules) to `Universal/FOLLOW-workflows-and-guides/playbooks/`
- A glossary term turns out to be engagement-wide, not initiative-specific. Promote to engagement-level glossary

Promotion follows the standard `change-protocol.md` sweep. Append a row to the relevant decisions ledger.

## Cross-references

- Parent playbook: `portable-ai-ecosystem.md`
- Engagement-level bootstrap (run before any initiative): `engagement-bootstrap-from-urls.md`
- Meeting transcripts file into this initiative's `READ-references-and-knowledge/meetings-and-transcripts/`: `process-meeting-transcripts.md`
- Folder-creation rules (every folder needs a README in the same change): `folder-creation-rules.md`

*History: [Universal/RECORD-decisions/_index.md](../../RECORD-decisions/_index.md)*
