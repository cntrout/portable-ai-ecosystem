---
type: playbook
last_reviewed: 2026-05-27
sync_trigger: 2026-05-27-portable-ai-ecosystem-decisions-and-voice-pass
depends-on:
  - playbook:portable-ai-ecosystem
  - playbook:voice-composition
  - playbook:folder-creation-rules
  - playbook:change-protocol
---

# Engagement Bootstrap From URLs Playbook

Spin up a fresh engagement-specific knowledge layer on the AI ecosystem given only the client's public-facing URLs. Replaces the manual, drift-prone "create folders, hand-write voice, write thesis" pattern with a deterministic URL-driven bootstrap that delegates the heavy lifting to deep-research agents.

Designed as the companion to `portable-ai-ecosystem.md` for client devices where no past-client content is allowed to ship. Also useful on the operator's personal device any time a new engagement starts and there's no pre-existing private context to seed from.

## When to run this

- First-time setup on a new client device, immediately after `portable-ai-ecosystem.md` completes
- A new engagement begins on the current device and there's no pre-existing private context
- Major company-side change (rebrand, repositioning, M&A) warrants a re-bootstrap of the public-facing layer
- Onboarding a new engagement quickly without hand-authoring brand, voice, and glossary files

## Outcome

Fresh, public-information-only content populated across the engagement-specific layer:

- `READ-references-and-knowledge/brand-assets/`: captured brand pages, extracted color/typography references, logo descriptions, brand voice cues
- `READ-references-and-knowledge/product-knowledge/`: captured product pages, feature summaries, terminology, public roadmap if available
- `READ-references-and-knowledge/glossary.md`: company-specific terms compiled from docs, product pages, and blog
- `READ-references-and-knowledge/people.md`: public roster only, from leadership / careers / about pages (if URLs provided)
- `READ-references-and-knowledge/thesis.md`: initial company thesis derived from positioning, competitive context, public strategy signals
- `FOLLOW-workflows-and-guides/voice/voice.md`: Layer-3 voice file derived from blog, brand, and product copy (the company writing in its own words)
- `_index.md` and `README.md` updates so the new content is discoverable
- A one-line entry in `Universal/RECORD-decisions/_index.md` recording the bootstrap

## Inputs

| Required | Optional but recommended | Optional |
|---|---|---|
| Company homepage URL | Brand / style guide URL | Leadership / team page URL |
| | Product docs URL | Careers / about page URL |
| | Blog or newsroom URL | Public roadmap URL |
| | Public glossary URL (if any) | Recent press / news article URL |
| | Pricing or product pages URL | Investor relations / public filings URL (if relevant) |

Missing optional inputs are fine. The playbook proceeds with what's available and notes the gaps in `open-questions.md`.

## Constraints (hard rules, do not violate)

- **Public-facing URLs only.** No URLs behind login walls, paywalls, or company VPNs. If a URL is behind auth, ask the operator before proceeding.
- **Public information only in the outputs.** Anything sensitive that surfaces during research (internal customer lists, pricing in restricted markets, confidential strategy) gets dropped from the populated files. The bootstrap produces a public-information layer. Sensitive context gets layered on top later via meetings, decisions, and operator-authored docs.
- **Draft, never final.** Every file the bootstrap creates is marked as a draft with a TODO header at the top. The operator reviews and accepts before content is treated as authoritative.
- **Fails gracefully.** A 404, a paywall, a JS-rendered page, or a complete absence of a category (e.g., no public blog) is logged in `bootstrap-gaps.md`, and the playbook proceeds with what's available.

## Procedure

### 1. Inputs collection (5 min)

Open a `claude` session in the working folder. Provide URLs as a structured list:

```
Company: {Company Name}
Required:
  homepage: {URL}
Recommended:
  brand: {URL or "none"}
  docs: {URL or "none"}
  blog: {URL or "none"}
  glossary: {URL or "none"}
  pricing: {URL or "none"}
Optional:
  team: {URL or "none"}
  careers: {URL or "none"}
  roadmap: {URL or "none"}
  press: {URL or "none"}
```

Claude validates each URL is reachable via `WebFetch` and reports the categories that returned usable content vs. the ones that need a fallback.

### 2. Spawn parallel research agents (15-30 min wall clock)

Claude launches up to five `Agent` calls in parallel (one tool-use message, multiple tool blocks). Each agent has a single, scoped responsibility and writes its output to a single file in a staging directory under `/tmp/engagement-bootstrap-{slug}/`.

| Agent | Responsibility | Output file |
|---|---|---|
| Brand & voice extractor | Reads homepage + brand + blog + product pages. Extracts color tokens, typography references, logo descriptions, voice cues (tone, vocabulary, sentence shape). Builds a Layer-3 voice file in the format used by the framework's `Universal/FOLLOW-workflows-and-guides/voice/voice.md` schema. | `brand-and-voice.md` |
| Product knowledge extractor | Reads docs + product pages + public roadmap. Captures feature summaries, terminology, integration patterns, key product surfaces. | `product-knowledge.md` |
| Glossary extractor | Reads docs + product + blog + glossary URL if available. Pulls company-specific terms, acronyms, jargon. Sources are linked per term. | `glossary.md` |
| People extractor | Reads team / careers / about pages if URLs provided. Captures public roster only: names, titles, public bios. No emails, no personal context, no inferred relationships. | `people.md` |
| Thesis builder | Reads homepage + blog + press + public roadmap. Builds an initial company thesis: what they do, who they serve, what their public strategy signals, where the market is going. Cites public sources for every claim. | `thesis.md` |

The agents run independently. Each is reminded explicitly: *public information only; cite sources; mark uncertain claims; do not infer beyond what's stated publicly.*

### 3. Aggregation (5 min)

Once all agents return, Claude reads the five staging files, surfaces any conflicts between them (e.g., the voice agent says "casual" but the product agent quotes formal docs language), and produces a consolidated change set for the operator to review.

The change set is presented as a single chat message with: per-file summary, conflict callouts, gaps log, and the proposed disposition for each output file (create / update existing / skip).

### 4. Review and edit (15-45 min, operator's pacing)

The operator reviews the staging files in the working folder. Edit-in-place is fine. The default disposition is: *accept what's clearly correct, reject anything that crosses the public-information line, mark anything ambiguous as TODO and continue.*

Common edit patterns:

- Strip any sentence that infers internal strategy ("they likely will...") and replace with a question in `open-questions.md`
- Compress lists where the research agent over-itemized
- Add a TODO header to any file that's directionally right but needs the operator to layer on private context later
- Remove any sentence that names a customer without a public source

### 5. Commit to the engagement layer (10 min)

Once the operator accepts the staging files, Claude moves them into the right paths:

```
{staging}/brand-and-voice.md       →  Universal/FOLLOW-workflows-and-guides/voice/voice.md
{staging}/product-knowledge.md     →  Universal/READ-references-and-knowledge/product-knowledge/_overview.md
{staging}/glossary.md              →  Universal/READ-references-and-knowledge/glossary.md
{staging}/people.md                →  Universal/READ-references-and-knowledge/people.md
{staging}/thesis.md                →  Universal/READ-references-and-knowledge/thesis.md
```

Plus:

- Update `Universal/READ-references-and-knowledge/README.md` to reference the new files
- Seed `Universal/READ-references-and-knowledge/open-questions.md` with the gaps log
- Append a one-line row to `Universal/RECORD-decisions/_index.md`:
  > `YYYY-MM-DD | Engagement bootstrap completed for {Company Name}. {N of M} URL categories populated; gaps logged in open-questions.md. | Universal | engagement-bootstrap-from-urls run | (rationale in this ledger row + bootstrap-gaps.md if material gaps exist)`

### 6. Smoke test (5 min)

In a fresh `claude` session inside the working folder, run three prompts:

| Prompt | Expected response shape |
|---|---|
| "What does {Company} do?" | Claude paraphrases the thesis without inventing facts not in the populated files |
| "Self-attest the voice you'd use for a customer-facing one-pager." | Claude reports the 4-step voice composition rule loading Layers 1 + 2 + 3, and Layer 3 references the newly-populated `voice.md` |
| "What are 3 company-specific terms I should know?" | Claude pulls from the new `glossary.md` |

All three green = engagement layer is live. The first initiative can now start.

## Constraints on agent prompting

When invoking the five parallel research agents, the prompts must include:

- **The full input URL list.** Every agent sees every URL; context matters.
- **The shape of the expected output file.** A fenced markdown block showing the exact schema.
- **An explicit "public information only" guardrail.**
- **A "cite the source URL for every claim" requirement.**
- **A "fail gracefully" instruction.** Log missing categories, don't hallucinate.
- **The character of the AI ecosystem the agent is serving.** One sentence: this populates a Layer-3 voice / glossary / etc. for the AI ecosystem that supports the operator's work on this engagement.

Prompt templates for each of the five agents are kept in this playbook's appendix below to avoid drift.

## Failure modes

| Failure | Recovery |
|---|---|
| URL returns 404 / 403 | Log in `bootstrap-gaps.md`, proceed with available URLs |
| URL behind paywall or login | Ask the operator for an alternative public URL; if none, log and proceed |
| URL returns JS-rendered shell with no content | Fall back to Claude in Chrome (if MCP available). If not, mark as a gap and proceed |
| Voice extraction yields nothing usable | Ship `voice.md` with structural skeleton + TODO header. The operator authors Layer 3 manually |
| Two agents produce conflicting signals (e.g., tone) | Surface the conflict to the operator in the aggregation step; the operator picks |
| Agent timeout / error | Re-run that single agent with a tightened scope; don't block the others |
| Sanitization scan flags content in the populated files | Strip flagged content. If structural, restart the relevant agent with a stricter prompt |

## Appendix: agent prompt templates

Each template shipped under `Universal/READ-references-and-knowledge/concepts/engagement-bootstrap-agent-prompts/`:

- `brand-and-voice-extractor.md`
- `product-knowledge-extractor.md`
- `glossary-extractor.md`
- `people-extractor.md`
- `thesis-builder.md`

These are kept as concept docs (not embedded in this playbook) so that prompt revisions don't trigger a change-protocol sweep on the playbook itself, only on the concept doc. Templates are loaded by the playbook at runtime.

(Templates themselves are deferred to v1.1. For the first engagement run, Claude composes the prompts inline based on this playbook's schema. The concept-doc-driven version is a refactor once the schema is stable.)

## Cross-references

- Parent playbook: `portable-ai-ecosystem.md`
- Voice composition rule (consumed by the brand-and-voice agent): `voice-composition.md`
- Folder-creation rules (consumed at commit time): `folder-creation-rules.md`
- Decisions ledger entry format: `change-protocol.md` §"Decisions ledger interaction"

*History: [Universal/RECORD-decisions/_index.md](../../RECORD-decisions/_index.md)*
