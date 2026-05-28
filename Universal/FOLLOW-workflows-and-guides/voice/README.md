# Universal Voice

Three-layer writing-guidelines system that shapes ALL output Claude produces
on your behalf. Markdown-only, human-readable, shareable.

---

## The three layers

```
Layer 1, UNIVERSAL DO-NOT      do-not.md          forbidden patterns, AI tells
Layer 2, PERSONAL BASELINE     personal.md        your natural voice (extracted from sent emails)
   + augment                   formats.md         5 sections: email, Slack, doc, ticket, presentation
Layer 3, ENGAGEMENT BRAND      voice.md           client's voice (extracted from their surfaces)
```

Composition rule lives in `Universal/FOLLOW-workflows-and-guides/playbooks/voice-composition.md`; that's
the file Claude reads to know HOW to assemble the layers at output time.

## Files in this folder

| File | Purpose |
|---|---|
| `README.md` | this file, convention + privacy contract |
| `do-not.md` | Layer 1, universal forbidden patterns |
| `personal.md` | Layer 2, your baseline voice |
| `formats.md` | Layer 2 augment, per-format conventions |
| `voice.md` | Layer 3, engagement-layer brand voice (single client per device) |

Single-client-per-device model: Layer 3 lives next to the other layers at
`Universal/FOLLOW-workflows-and-guides/voice/voice.md`. Populate it from
the active engagement's materials.

**Layer 3 status:** populate when an engagement is active.

| Status | Notes |
|---|---|
| Populated | Extracted from sources (marketing site, product surfaces, call transcripts, glossary). |
| Deferred | Pre-engagement, no real materials yet, or placeholder only. |

## Privacy contract (binding)

Applies to any voice-extraction work that touches private content (emails,
DMs, internal docs).

1. **Emails are read from the email MCP only.** Never from a local cache, never
   from a third-party service, never persisted to disk.
2. **Email contents stay in conversation context during analysis.** They
   are NOT written to vault files, NOT logged, NOT sent to any service
   beyond the conversation.
3. **Output (`personal.md`) contains style observations ONLY.** Sentence-
   length distribution, hedging patterns, sign-off conventions, vocabulary
   tendencies. NEVER:
   - Quoted email content
   - Subject lines
   - Recipient names
   - Email addresses
   - Specific dates or company-specific details
4. **Pre-save verification.** Before `personal.md` is written, run a
   grep-style check for: email addresses, recipient names, company names,
   any quoted phrase >5 words. Flag any match for review before
   save.
5. **Intermediate drafts deleted via the `_trash/` quarantine pattern**
   (the sandbox can't `rm`; `mv` to `_trash/YYYY-MM-DD/` and empty
   via Finder).
6. **Sample size: start with ~30 sent emails**, not 100. Validate signal,
   expand if needed. Less data through the pipeline = less privacy surface.

Same contract applies to any third-party voice source (Slack DMs, etc.) if
that work ever happens.

## Composition (TL;DR, full playbook elsewhere)

For any written output Claude produces:

1. Always apply `do-not.md`
2. Always apply `personal.md` + the relevant section of `formats.md`
3. If the output is customer-facing (default ON, opt-out cues in
   playbook): apply `voice.md` (the engagement brand layer)
4. Self-attest in chat: `Voice loaded: <layers>` at top of reply

Full rule: [`Universal/FOLLOW-workflows-and-guides/playbooks/voice-composition.md`](../playbooks/voice-composition.md).

## How discovery and analysis populate these files

These files are populated by whatever brand-discovery and voice-analysis
tooling the operator has available. Typical flow:

| Step | Used for |
|---|---|
| Brand discovery | Layer 3, find the engagement's brand materials across Notion, transcripts, marketing site, product surfaces. |
| Document analysis | Layer 2, extract voice attributes from the operator's sent emails. |
| Conversation analysis | Layer 3, extract patterns from client call transcripts. |
| Guideline generation | Produce the first draft of `personal.md` or `voice.md` from raw materials. |
| Voice enforcement at output time | Apply the layered guidelines via the composition playbook (no plugin required; the playbook is the runtime). |
| Pre-ship QA review | Optional pass that validates significant outputs against the loaded guidelines before sending. |

## Retention

No auto-cleanup. Voice files get updated as your voice evolves or as
client brands evolve. Date-stamp updates in the file footer.

## Sharing

This whole structure is portable. Anyone wanting the same setup
would:
1. `mkdir -p Universal/FOLLOW-workflows-and-guides/voice/`
2. Drop their own `do-not.md` / `personal.md` / `formats.md` (plus `voice.md`
   when an engagement is active)
3. Add a 5-line reference in their AGENTS.md / CLAUDE.md
4. Use the same composition playbook (verbatim) or adapt

Plain markdown, plain rules. Nothing proprietary.
