---
name: engagement-bootstrap-from-urls
description: Bootstraps a fresh engagement-specific knowledge layer (brand assets, product knowledge, glossary, people, thesis, voice Layer 3) from the client's public-facing URLs. Spawns 5 parallel research agents per the engagement-bootstrap-from-urls playbook, aggregates results, presents to the user for review, files into the engagement layer. Use on a new client device after install, or any time a new engagement needs initial public-information seeding. Public-information-only by hard rule.
allowed-tools: Read, Write, Edit, WebFetch, Bash, Glob, Grep, Agent
---

# Engagement Bootstrap From URLs

Runtime for the procedure in `Universal/FOLLOW-workflows-and-guides/playbooks/engagement-bootstrap-from-urls.md`. The playbook is the spec, including hard constraints, failure modes, and the file-disposition rules.

## When this skill fires

The user has a new client device or new engagement and wants the public-information knowledge layer seeded from URLs rather than hand-authored.

## Steps

### Step 1: Collect URLs

Ask the user for:
- **Required:** company homepage URL
- **Recommended:** brand/style URL, product docs URL, blog URL, glossary URL, pricing URL
- **Optional:** team/about URL, careers URL, public roadmap URL, recent press URL

Accept "none" for any missing category. For each provided URL, run `WebFetch` to confirm it returns content. Report which categories are usable, which gave 404, which look like JS-rendered shells, and which are gated behind login (skip those with a note).

### Step 2: Stage a working directory

Generate a kebab-case slug from the company name. Create `/tmp/engagement-bootstrap-{slug}/` for the five staging files.

### Step 3: Spawn 5 parallel research agents

In a single tool-use message with multiple `Agent` tool blocks, launch:

1. **Brand & voice extractor**: reads homepage + brand + blog + product pages. Extracts color tokens, typography references, logo descriptions, voice cues (tone, vocabulary, sentence shape). Builds a Layer-3 voice file in the schema of `Universal/FOLLOW-workflows-and-guides/voice/voice.md`. Output: `/tmp/engagement-bootstrap-{slug}/brand-and-voice.md`.
2. **Product knowledge extractor**: reads docs + product pages + public roadmap. Captures features, terminology, integration patterns, key product surfaces. Output: `product-knowledge.md`.
3. **Glossary extractor**: reads docs + product + blog + glossary URL. Pulls terms with their source URLs linked per term. Output: `glossary.md`.
4. **People extractor**: reads team / careers / about pages if provided. Captures public roster only: names, titles, public bios. No emails, no personal context, no inferred relationships. Output: `people.md`.
5. **Thesis builder**: reads homepage + blog + press + public roadmap. Builds the initial company thesis: what they do, who they serve, public strategy signals, market direction. Cites public sources per claim. Output: `thesis.md`.

Every agent prompt MUST include:

- Full input URL list (every agent sees every URL so context is shared)
- Expected output schema as a fenced markdown block
- Explicit "public information only" guardrail
- "Cite source URL per claim" requirement
- "Fail gracefully" instruction
- One-sentence statement of what the AI ecosystem is and what the agent contributes

Use the prompt template structure from `engagement-bootstrap-from-urls.md` §"Constraints on agent prompting".

### Step 4: Aggregate

Once all agents return, read the 5 staging files. Surface to the user in a single chat message:

- **Per-file summary** (one paragraph each)
- **Conflict callouts** between files (e.g., voice agent says "casual" but product docs read formal)
- **Gaps log** (which URLs returned nothing usable, which categories are empty)
- **Proposed disposition per output file** (create new / update existing / skip)

### Step 5: User review

Pause for the user to review the staging files. They edit in place. Default disposition: accept what's clearly correct, reject anything crossing the public-information line, mark ambiguous as TODO and continue.

Surface common edit patterns from the playbook: strip inferred internal strategy sentences, compress over-itemized lists, add TODO headers where the operator needs to layer in private context later, remove unsourced customer name references.

### Step 6: Commit to the engagement layer

Once the user accepts the staging files, move them:

```
{staging}/brand-and-voice.md       →  Universal/FOLLOW-workflows-and-guides/voice/voice.md
{staging}/product-knowledge.md     →  Universal/READ-references-and-knowledge/product-knowledge/_overview.md
{staging}/glossary.md              →  Universal/READ-references-and-knowledge/glossary.md
{staging}/people.md                →  Universal/READ-references-and-knowledge/people.md
{staging}/thesis.md                →  Universal/READ-references-and-knowledge/thesis.md
```

Update `Universal/READ-references-and-knowledge/README.md` to reference the new files. Seed `Universal/READ-references-and-knowledge/open-questions.md` with the gaps log from Step 1.

Append to `Universal/RECORD-decisions/_index.md`:

```
| {YYYY-MM-DD} | Engagement bootstrap completed for {Company}. {N of M} URL categories populated; gaps logged in open-questions.md. | Universal | engagement-bootstrap-from-urls skill | (rationale in this ledger row + bootstrap-gaps.md if material gaps exist) |
```

### Step 7: Smoke test

Run the 3 smoke prompts from the playbook §"6. Smoke test":

1. "What does {Company} do?" → expect Claude to paraphrase the thesis without inventing facts
2. "Self-attest the voice you'd use for a customer-facing one-pager." → expect 4-step composition rule loading Layers 1 + 2 + 3, with Layer 3 referencing the new voice.md
3. "What are 3 company-specific terms I should know?" → expect Claude to pull from the new glossary.md

Report PASS / FAIL per prompt. All 3 green = engagement layer is live; first initiative can start.

## Hard constraints

- **Public-facing URLs only.** Anything behind login, paywall, or VPN gets escalated to the user, never auto-bypassed.
- **Public information only in outputs.** Sensitive content discovered during research is dropped before commit.
- **Draft, never final.** Every populated file starts with a TODO header until the user accepts.
- **Fail gracefully.** Missing categories get logged, not faked.

## Failure handling

Per the playbook §"Failure modes" table. Surface failures to the user with a recovery option each.

## Cross-references

- Spec: `Universal/FOLLOW-workflows-and-guides/playbooks/engagement-bootstrap-from-urls.md`
- Parent: `Universal/FOLLOW-workflows-and-guides/playbooks/portable-ai-ecosystem.md`
- Voice schema referenced by Agent 1: `Universal/FOLLOW-workflows-and-guides/voice/voice.md`
