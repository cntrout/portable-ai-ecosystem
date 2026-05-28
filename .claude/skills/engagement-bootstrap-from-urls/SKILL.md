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

## State-file participation

The `initial-install` orchestrator skill writes `.claude/_install-state/state.json` to track install progress across resumable sessions. When `engagement-bootstrap-from-urls` runs (whether the operator invokes it directly OR the orchestrator delegates to it at State 10), it participates in that state file as a co-operative writer. The orchestrator owns the file; this skill writes only its own per-skill block.

Stand-alone invocation is still fully supported. If `.claude/_install-state/state.json` does not exist, the skill behaves exactly as documented above (collects URLs, spawns agents, stages files, files into the engagement layer, appends the ledger row, runs the smoke test). No state-tracking; the skill is unchanged.

### When state.json exists

1. **Read state.json at start.** Path: `{framework_root}/.claude/_install-state/state.json` (where `{framework_root}` is the output of `git rev-parse --show-toplevel`). Parse it. If the file has `orchestrator_active: true`, record locally that this skill is running as part of an orchestrated install.

2. **Use the lock file convention.** Before writing to state.json, check for `{framework_root}/.claude/_install-state/.lock`. If the lock exists and its modification time is fresher than 5 minutes, wait briefly and re-check, or abort the state.json write and surface to the operator. The engagement-layer file writes and the ledger row append still happen regardless of the lock; only the state.json update is gated. Full lock semantics (PID, stale-cleanup) are owned by the orchestrator.

3. **Write the per-skill block on completion.** After the engagement-layer files are committed and the ledger row is appended, update `state.json` with a `skill_runs["engagement-bootstrap-from-urls"]` block:

   ```json
   {
     "last_run_at": "2026-MM-DDTHH:MM:SS",
     "outcome": "partial",
     "summary": "4 of 5 URL categories populated; people.md failed (no public team page); 1 of 6 URL inputs returned 404",
     "invoked_by": "orchestrator"
   }
   ```

   Outcome values:
   - `success`: homepage returned, all 5 agents produced output, all 5 engagement-layer files committed
   - `partial`: homepage returned, but some URL categories 404'd, were login-gated, or one or more agents failed gracefully; at least one engagement-layer file is populated
   - `failed`: homepage 404 or unreachable, or 0 of 5 agents produced usable output
   - `skipped`: operator aborted before Step 6 (no engagement-layer files were committed)

   The `invoked_by` value is `orchestrator` if `orchestrator_active: true` was read at start; otherwise `operator`.

   The `summary` field should include URL category counts. Format: "{N} of {M} URL categories populated; {failed} failed; {skipped} skipped". Cite specific categories when material (e.g., "people.md skipped, no public team page").

4. **Atomic write.** Use the `mktemp` + `mv` pattern so a partial write never corrupts state.json:

   ```bash
   tmp=$(mktemp "$STATE_FILE.XXXXXX")
   {updated_json} > "$tmp"
   mv "$tmp" "$STATE_FILE"
   ```

### state.json contract

The full contract (owned by the orchestrator):

```json
{
  "version": "1.0",
  "schema_version": 1,
  "orchestrator_active": true,
  "current_state": "S10_engagement",
  "started_at": "2026-MM-DDTHH:MM:SS",
  "last_updated_at": "2026-MM-DDTHH:MM:SS",
  "completed_states": ["S0_clone", "S1_bootstrap", "S2_session", "S3_validated", "..."],
  "skill_runs": {
    "validate-install": { },
    "initial-setup": { },
    "engagement-bootstrap-from-urls": {
      "last_run_at": "2026-MM-DDTHH:MM:SS",
      "outcome": "partial",
      "summary": "4 of 5 URL categories populated; people.md failed (no public team page)",
      "invoked_by": "orchestrator"
    }
  }
}
```

This skill only writes its own `skill_runs["engagement-bootstrap-from-urls"]` block plus a refresh of `last_updated_at`. It never modifies `current_state`, `completed_states`, or other skills' blocks. Those are the orchestrator's.

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
