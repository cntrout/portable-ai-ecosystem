---
type: playbook
last_reviewed: 2026-05-28
sync_trigger: 2026-05-28-v1.2-skills-batch
depends-on:
  - playbook:voice-composition
  - playbook:change-protocol
  - playbook:folder-creation-rules
---

# Operator Voice Bootstrap Playbook

Regenerate the Layer 2 baseline voice file (`Universal/FOLLOW-workflows-and-guides/voice/personal.md`) from the operator's own writing samples. The shipped `personal.md` is the framework author's voice as a worked example; this playbook replaces it with patterns extracted from how you actually write.

Sibling to `engagement-bootstrap-from-urls`. That playbook handles Layer 3 (engagement-specific voice from public URLs). This one handles Layer 2 (your personal voice baseline from your own samples). Together they cover the two operator-customizable voice layers; Layer 1 (`do-not.md`) is universal and stays portable across forkers.

## When to run this

- **First install of a forked framework.** The shipped `personal.md` contains the framework author's voice as the worked example. If you don't want Claude producing output in someone else's voice patterns, run this skill once during initial install (or shortly after) to replace it with yours.
- **Voice mismatch detected.** Output Claude generates on your behalf doesn't sound like you. The patterns captured in `personal.md` no longer reflect how you write today.
- **Periodic re-bootstrap.** Your writing style evolved (new role, new register, new audience, new domain) over the last 6-12 months. The captured patterns are stale.
- **New writing corpus available.** You collected a fresh body of samples (recent emails, a series of new blog posts, a quarter of Slack history) that's worth re-extracting from.

Not for: small tweaks to specific rules. Edit `personal.md` directly for those. This playbook is for full regeneration when the existing patterns no longer represent the operator's voice.

## Outcome

A new `Universal/FOLLOW-workflows-and-guides/voice/personal.md` populated from the operator's writing samples, matching the existing schema exactly so the voice-composition loader works without changes.

Specifically:

- `personal.md` overwritten with operator-extracted patterns
- Old `personal.md` quarantined to `_trash/{YYYY-MM-DD}/personal.md` with a manifest entry
- `.claude/_setup-state/config.json` updated: `voice.personal_md_status: operator-customized`
- One-line entry appended to `Universal/RECORD-decisions/_index.md`
- Smoke test passes: voice attestation reads `Voice loaded: do-not + personal + {format} (internal)` with no `:default` suffix on personal
- Optional: `change-protocol-sweep` invoked if voice rules changed in ways that affect existing files

## Inputs

| Required | Optional but recommended | Optional |
|---|---|---|
| Minimum 50 writing samples | 100-200 samples for stronger signal | Samples from 2+ registers (email + Slack, or doc + post) |
| At least one accessible source (file paths, pasted text, or a directory of files) | Mixed format coverage (the format-specific extractor needs at least one sample per format you want covered) | Public-writing URLs (blog, Substack, LinkedIn posts the operator authored) |

Accepted sample sources:

| Source | Why useful | Privacy note |
|---|---|---|
| Local markdown / text files | Easiest. Operator-controlled. | All processing local. |
| Exported email (.mbox, .eml, plain text) | High signal, structured, recipient-aware register. | Local-only. Never transmitted. |
| Exported Slack history (.json or text) | Catches short-form / casual register. | Local-only. Never transmitted. |
| Pasted text in chat | Quick start; useful for ad-hoc samples. | Stays in context, written to local staging only. |
| Operator's public writing (blog posts, Substack, LinkedIn posts the operator owns) | Long-form register; no privacy contract overhead. | Operator-pointed URLs only. |

Below the minimum (20 samples), the skill refuses. Between 20 and 50, the skill warns and offers to proceed with a `low-confidence` note in the file header or to defer.

## Output schema

The regenerated `personal.md` MUST ship the same sections as the existing worked example so `voice-composition.md`'s 4-step composition rule works without changes. Sections in order:

| Section | What goes in it | Source agent |
|---|---|---|
| Header note | "Regenerated YYYY-MM-DD from {N} writing samples across {formats}. Replaces the framework author's worked example." | Aggregation step |
| § Voice | 2-3 paragraphs of warmth / register / temperature observations. Adjectives that fit + adjectives that don't. | Synthesized across all 5 agents |
| § Sentence shape | Mean + median + distribution (% short / medium / long). | Sentence-shape extractor |
| § Hedging + conviction | Overt hedging rate, warmth-offering rate, conditional softener rate, confidence-marker rate, apology rate (all per 1,000 words). | Hedging + conviction extractor |
| § Sign-offs | Default + variants + frequency. Per format if relevant. | Vocabulary extractor |
| § Common vocabulary | Characteristic words and structural moves the operator uses naturally. | Vocabulary extractor |
| § Punctuation and mechanics | Exclamation rate, em-dash rate, contraction frequency, quote style, emoji usage by register. | Punctuation extractor |
| § Format-specific tendencies | Per format observed: opener, body shape, close. Cross-references to `formats.md`. | Format-specific extractor |
| § What the operator avoids naturally | Items from `do-not.md` the operator's own writing already avoids (called out so the rule doesn't have to police them). | Synthesized from all 5 agents against `do-not.md` |
| Application notes | 4-step composition order pointing at `do-not.md`, this file, `formats.md`, engagement-layer `voice.md`. | Static, copied from the existing template |

The operator's voice content can be totally different from the worked example. Only the structure is preserved.

## Constraints (hard rules, do not violate)

- **Privacy: samples stay local.** Writing samples are read in-context by Claude and the spawned subagents. They are never sent to third-party services, never persisted beyond the skill's staging directory, and never quoted longer than 5 words in the final `personal.md`. The output file contains style observations, not source content.
- **No PII or attribution in the output.** Names of people the operator wrote to, company names from the samples, specific quoted phrases beyond short patterns: stripped before commit. The output file is safe to commit to a public framework repo because it contains observations only.
- **Operator-reviewed before commit.** The aggregated draft is presented to the operator for review. The skill does not overwrite `personal.md` without explicit acceptance.
- **Schema preservation.** Section structure matches the existing `personal.md` exactly so the voice-composition.md loader works without changes. Section *content* can be totally different from the worked example; section *structure* is fixed.
- **Quarantine, never delete.** The old `personal.md` moves to `_trash/{YYYY-MM-DD}/` with a manifest entry. The operator empties the trash manually via Finder.
- **Minimum sample threshold.** Below 20 samples: refuse. Between 20 and 50: warn. 50+ is the recommended floor; 100-200 is the comfortable signal range.

## Procedure

### 1. Intent confirmation (1 min)

Open a `claude` session. The skill asks: "This will overwrite `personal.md` with patterns extracted from your samples. The old file gets quarantined to `_trash/{YYYY-MM-DD}/`. Proceed?" Operator confirms or aborts.

If aborted, nothing changes. The skill exits clean.

### 2. Sample collection (5-15 min, operator-paced)

Operator provides samples in any combination of:

- File paths (single files or directories the skill globs)
- Pasted text directly into chat
- URLs to operator-authored public writing (blog posts, Substack, LinkedIn the operator owns)

The skill stages each sample to `/tmp/operator-voice-bootstrap-{YYYY-MM-DD-HHMM}/samples/` as numbered files (`001.txt`, `002.txt`, etc.). Sample numbering lets the subagents reference by index rather than quoting content back.

The skill reports the count, the inferred format distribution, and any below-threshold warnings.

### 3. Spawn 5 parallel research subagents (10-20 min wall clock)

In a single tool-use message with five parallel subagent invocations, the skill launches:

| Subagent | Reads | Produces | Output file |
|---|---|---|---|
| Sentence-shape extractor | All staged samples | Mean / median sentence length, word-count distribution (% short ≤8, % medium 9-20, % long >20), rhythm variance vs. uniformity, paragraph-length tendencies | `sentence-shape.md` |
| Hedging + conviction extractor | All staged samples | Overt hedging rate ("I think," "maybe," "perhaps"), warmth-offering rate ("happy to," "would love to," "glad to"), conditional softener rate ("if that works," "if you need"), confidence marker rate ("definitely," "absolutely," "for sure"), apology rate ("sorry," "apologies"). Per 1,000 words. | `hedging-conviction.md` |
| Vocabulary extractor | All staged samples | Characteristic words and structural moves: workhorse intensifiers, acknowledgment openers, action-update constructions, soft-close patterns, gratitude phrases, sign-off variants. Frequency-ranked. | `vocabulary.md` |
| Punctuation extractor | All staged samples | Exclamation rate per 100 words, em-dash rate, contraction frequency, quote style (curly vs. straight), emoji presence by register, ellipsis and dash conventions | `punctuation.md` |
| Format-specific extractor | All staged samples, grouped by inferred format | Per format (email, Slack, doc, post): opener pattern, body shape, close pattern. Flags formats present + formats missing from the corpus. | `format-tendencies.md` |

Every subagent prompt MUST include:

- Path to the staged samples directory
- Expected output schema as a fenced markdown block matching the corresponding section of the existing `personal.md`
- The privacy rule: **observations only; never quote sample content longer than 5 words; never name people or companies surfaced in the samples**
- The "report by index, never by content" instruction (samples are referenced as `001.txt`, not by their text)
- One-sentence statement of what `personal.md` is and where it gets loaded

### 4. Aggregation (5 min)

The skill reads the 5 staging files and produces:

- **Per-section summary** (one paragraph each)
- **Conflict callouts** between agents (e.g., punctuation extractor reports moderate em-dash use but `do-not.md` bans them; flag for operator resolution)
- **Universal-floor conflicts** with `do-not.md` (e.g., operator's natural vocab includes "leverage" but `do-not.md` bans it; surface as a choice point: override universal rule in personal layer, or accept universal and let it police the natural pattern)
- **Coverage gaps** (formats missing from the corpus, registers under-represented, sample-count warnings)
- **Proposed `personal.md` draft** compiled into the schema

The draft lands at `/tmp/operator-voice-bootstrap-{stamp}/personal.md` for operator review.

### 5. Operator review (10-30 min, operator-paced)

Operator reviews the draft. Common edits:

- Tighten the vocabulary section to remove anomalies the operator doesn't recognize as theirs
- Adjust sign-off variants to match the operator's actual default and any rare variants
- Reconcile conflicts with `do-not.md` (override or accept)
- Add the "Application notes" section pointing to the correct downstream files
- Edit the header note's wording

Edit-in-place is fine. Default disposition: accept what's clearly right, edit what's close but off, mark anything ambiguous as TODO and continue.

### 6. Commit (3 min)

Once the operator accepts the draft:

1. Quarantine the old `personal.md`:
   ```bash
   mkdir -p _trash/{YYYY-MM-DD}/
   mv Universal/FOLLOW-workflows-and-guides/voice/personal.md _trash/{YYYY-MM-DD}/personal.md
   ```
   Append a row to `_trash/_manifest.md` per the file-deletion-constraint playbook.

2. Move the draft into place:
   ```bash
   mv /tmp/operator-voice-bootstrap-{stamp}/personal.md Universal/FOLLOW-workflows-and-guides/voice/personal.md
   ```

3. Update the file's header note to: `Regenerated {YYYY-MM-DD} from {N} writing samples across {formats present}. Replaces the framework author's worked example.`

4. Append to `Universal/RECORD-decisions/_index.md`:
   ```
   | {YYYY-MM-DD} | operator-voice-bootstrap completed. {N} samples processed; personal.md regenerated covering {format list}. | Universal | operator-voice-bootstrap skill | (rationale + summary of sample sources) |
   ```

5. Update `.claude/_setup-state/config.json`:
   ```json
   {
     "voice": {
       "personal_md_status": "operator-customized",
       "last_regenerated_at": "{YYYY-MM-DD}",
       "sample_count": {N},
       "formats_present": ["{format1}", "{format2}"]
     }
   }
   ```
   Preserve all other config keys. Use atomic write (`mktemp` + `mv`).

### 7. Optional change-protocol sweep (varies)

If the new `personal.md` changes voice rules in ways that affect downstream files (e.g., previous file had `Em dashes: zero` and new file has `Em dashes: moderate`, OR a high-frequency vocab preference flipped), the skill surfaces the diff to the operator and offers to invoke `change-protocol-sweep` per `Universal/FOLLOW-workflows-and-guides/playbooks/change-protocol.md`.

Default: ask before invoking. Skip if the regeneration is cosmetic (same patterns, fresher numbers).

### 8. Smoke test (2 min)

The skill generates a short test output in the new voice (a one-paragraph reply to a hypothetical "thanks for the update" message). Operator reads:

- The output itself
- The voice attestation line. Should read: `Voice loaded: do-not + personal + {format} (internal)`. No `:default` suffix on personal.

If the output sounds like the operator, regeneration is complete. If not, options: re-run with edits, or hand-tune specific sections of `personal.md` directly.

### 9. Clean up staging (1 min)

The skill deletes `/tmp/operator-voice-bootstrap-{stamp}/` once the operator accepts the output. Sample files leave no trace outside their original source locations.

Total wall-clock: ~30-60 min, depending on sample count and operator review pace.

## The 5 parallel research subagents (detailed responsibilities)

### Subagent 1: Sentence-shape extractor

**Reads:** all staged samples.

**Reports:**
- Mean sentence word count
- Median sentence word count
- Distribution: % short (≤8 words), % medium (9-20), % long (>20)
- Variance summary (is there real variance, or metronome cadence?)
- Paragraph-length tendencies (short / medium / long; per format if differentiated)

**Output schema:** matches the existing `§ Sentence shape` section of the worked-example `personal.md`. Two short paragraphs of observations, no quoted content.

### Subagent 2: Hedging + conviction extractor

**Reads:** all staged samples.

**Reports (all per 1,000 words):**
- Overt hedging rate ("I think," "maybe," "perhaps," "kind of," "sort of")
- Warmth-offering rate ("happy to," "would love to," "glad to")
- Conditional softener rate ("if that works," "if you need," "if it helps")
- Confidence marker rate ("definitely," "absolutely," "for sure," "totally")
- Apology rate ("sorry," "apologies," "my apologies")

**Notes:** which patterns are characteristic vs. absent. Calls out whether the hedge mode is self-doubt (high overt hedging) or optionality (high conditional softeners).

**Output schema:** matches the existing `§ Hedging + conviction` section. Bullet list of rates with one-line interpretive notes.

### Subagent 3: Vocabulary extractor

**Reads:** all staged samples.

**Reports:**
- Workhorse positive intensifier (e.g., "great," "awesome," "solid")
- Standard acknowledgment opener (e.g., "Thanks for...")
- Action-update construction (e.g., "I went ahead and...")
- Soft-close pattern (e.g., "Let me know")
- Gratitude phrasing
- Sign-off default + variants (frequency-ranked)
- Other characteristic structural moves (>= 3 occurrences in the corpus)

**Constraint:** ranked by frequency. Anomalies that appear once or twice get flagged but not promoted to the file.

**Output schema:** matches the existing `§ Common vocabulary` and `§ Sign-offs` sections. Bulleted list with one-line notes per item.

### Subagent 4: Punctuation extractor

**Reads:** all staged samples.

**Reports:**
- Exclamation rate per 100 words (high / medium / low / absent)
- Em-dash rate (should be near-zero per `do-not.md` Layer 1, but report the operator's natural rate for the conflict callout in aggregation)
- Contraction frequency (high / medium / low / absent)
- Quote style (straight vs. curly; report observed default)
- Emoji presence by register (email / Slack / doc)
- Ellipsis and dash conventions (single-period, multiple periods, hyphen vs. en-dash)

**Output schema:** matches the existing `§ Punctuation and mechanics` section.

### Subagent 5: Format-specific extractor

**Reads:** all staged samples, grouped by inferred format. Format inference cues: subject lines or "Hi {Name}" openers suggest email; short messages without headers suggest Slack; multi-paragraph structured content with headings suggests doc; long-form essay-style content suggests post.

**Reports per format observed:**
- Opener pattern (default + variants + frequency)
- Body shape (length, paragraph structure, list usage)
- Close pattern (sign-off, optional pre-sign-off lines)

**Flags:**
- Which formats appear in the corpus
- Which formats are missing (operator can add samples in a re-run)
- Cross-references to `formats.md` for each format observed

**Output schema:** matches the existing `§ Format-specific tendencies` section. One subsection per format observed.

## Constraints on subagent prompting

When invoking the 5 parallel subagents, the prompts must include:

- **The path to the staged samples directory.** Every subagent reads from the same staging directory.
- **The expected output schema as a fenced markdown block.** Matches the corresponding section of the existing `personal.md`.
- **An explicit privacy rule.** "Observations only. Never quote sample content longer than 5 words. Never name people or companies from the samples. Reference samples by their index (`001.txt`) rather than their content."
- **An explicit "report what's there, not what should be there" rule.** Subagents extract from the corpus; they don't infer what the operator "should" sound like.
- **A "fail gracefully" instruction.** If a section has low signal (too few samples for the inferred format, or too sparse for the metric), report `low-confidence` rather than inventing numbers.
- **The role of `personal.md`.** One sentence: this populates Layer 2 of the voice composition system, loaded for every output Claude produces on the operator's behalf.

Prompt templates for each subagent are kept inline in the skill's runtime for v1.2. The same concept-doc-driven refactor planned for `engagement-bootstrap-from-urls` (templates moved to `Universal/READ-references-and-knowledge/concepts/operator-voice-bootstrap-agent-prompts/`) is the future-release enhancement here too.

## Failure modes

| Failure | Recovery |
|---|---|
| Below 20 samples | Refuse. Ask the operator to gather more (50+ recommended). Exit clean. |
| 20-50 samples | Warn. Offer to proceed with a `low-confidence` header note, or defer. |
| Only one format present in the corpus | Proceed. Format-specific extractor produces a single subsection. Note the gap in the file. |
| One subagent returns no usable output | Re-run that single subagent with a tightened scope. Don't block the other four. |
| Subagent quotes sample content longer than 5 words | Aggregation step strips the quotes. Flag the violation to the operator. |
| Conflict between operator's natural pattern and `do-not.md` (e.g., natural use of a banned vocab word) | Surface in aggregation. Operator chooses: override universal in personal layer, or accept universal. |
| Operator rejects the draft outright | Keep the existing `personal.md` unchanged. Record the rejection in the decisions ledger. No quarantine, no commit. |
| Operator cancels mid-extraction | Staging files in `/tmp/` are not committed. Existing `personal.md` unchanged. No partial state. |
| State.json lock contention (under orchestrator) | Retry briefly per the engagement-bootstrap pattern. The `personal.md` write is not gated; only state.json is. |
| Voice rules changed in ways that affect downstream files | Surface the diff in Step 7 and offer to invoke `change-protocol-sweep`. Operator decides. |

## Cross-references

- Sibling playbook (Layer 3): `engagement-bootstrap-from-urls.md`
- Voice composition rule (consumed by the loader that reads the regenerated `personal.md`): `voice-composition.md`
- Universal voice floor (Layer 1, ships unchanged across operators): `Universal/FOLLOW-workflows-and-guides/voice/do-not.md`
- Format augment (Layer 2 sibling, ships with light customization): `Universal/FOLLOW-workflows-and-guides/voice/formats.md`
- Change-protocol sweep (optional Step 7): `change-protocol.md`
- File-deletion constraint (Step 6 quarantine): `Universal/READ-references-and-knowledge/concepts/file-deletion-constraint.md`
- Folder-creation rules (`_trash/{YYYY-MM-DD}/` quarantine path): `folder-creation-rules.md`

*History: [Universal/RECORD-decisions/_index.md](../../RECORD-decisions/_index.md)*
