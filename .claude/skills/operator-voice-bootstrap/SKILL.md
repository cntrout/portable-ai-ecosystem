---
name: operator-voice-bootstrap
description: Regenerates `Universal/FOLLOW-workflows-and-guides/voice/personal.md` (Layer 2 baseline voice) from the operator's own writing samples. Mirrors `engagement-bootstrap-from-urls` for engagement-specific voice; this one is operator-specific. Use after first install if you don't want to use the framework author's voice as-shipped, or any time your writing style evolves enough that the captured patterns no longer reflect how you actually write. Spawns parallel research subagents over the sample corpus, aggregates results, pauses for operator review, writes the new personal.md, and updates `.claude/_setup-state/config.json`.
allowed-tools: Read, Write, Edit, Bash, Glob, Grep
---

# Operator Voice Bootstrap

Runtime for the procedure in `Universal/FOLLOW-workflows-and-guides/playbooks/operator-voice-bootstrap.md`. The playbook is the spec, including hard constraints, the schema requirement, privacy rules, and failure modes.

This is the Layer 2 sibling to `engagement-bootstrap-from-urls`. That skill populates Layer 3 (engagement-specific voice) from public client URLs. This skill regenerates Layer 2 (your personal voice baseline) from your own writing samples so that everything Claude produces on your behalf sounds like you, not like the framework author whose voice ships in the worked-example `personal.md`.

## When this skill fires

You forked the framework and the shipped `personal.md` is still the worked example from the framework author's voice. Or your writing style has evolved (new role, new register, new audience) and the existing patterns no longer reflect how you actually write today.

The skill is idempotent. Re-run any time the patterns drift.

## Steps

### Step 1: Confirm intent

Ask the operator: "This will overwrite `Universal/FOLLOW-workflows-and-guides/voice/personal.md` with patterns extracted from your writing samples. The old file gets quarantined to `_trash/{YYYY-MM-DD}/personal.md`. Proceed?"

If no, exit. Record nothing.

If yes, continue.

### Step 2: Collect writing samples

Ask the operator for samples in any combination:

- **File paths** to local files (markdown, text, exported emails, exported Slack history)
- **Pasted text** directly into chat (longer pastes welcome; the skill stages them to disk)
- **A directory** containing multiple sample files (the skill globs it)

Constraints surfaced to the operator:

- **Minimum:** 50 samples (messages, paragraphs, posts) for any usable signal. Below 50 the skill warns and offers to defer.
- **Recommended:** 100-200 samples spanning at least two registers (e.g., email + Slack + a blog post or two).
- **Privacy:** samples stay on the operator's device. The skill reads them in-context, extracts style observations, and writes the observations to `personal.md`. The samples themselves are never quoted in the output file, never sent to any third party, and never persisted beyond the skill's staging directory.

Stage samples to `/tmp/operator-voice-bootstrap-{YYYY-MM-DD-HHMM}/samples/` for the subagents to read. Number them sequentially (`001.txt`, `002.txt`, etc.) so the agents can reference by index without quoting content back.

### Step 3: Spawn 5 parallel research subagents

In a single tool-use message with multiple subagent invocations, launch:

1. **Sentence-shape extractor**: reads all staged samples. Computes mean / median sentence length, word-count distribution (% short / medium / long), variance vs. uniformity, rhythm patterns. Output: `/tmp/operator-voice-bootstrap-{stamp}/sentence-shape.md`.
2. **Hedging + conviction extractor**: reads all staged samples. Measures overt hedging rate ("I think," "maybe," "perhaps"), warmth-offering rate ("happy to," "would love to"), conditional softener rate ("if that works"), confidence marker rate ("definitely," "absolutely"), apology rate ("sorry," "apologies"). Reports per-1,000-word counts. Output: `hedging-conviction.md`.
3. **Vocabulary extractor**: reads all staged samples. Identifies characteristic words and structural moves (workhorse intensifiers, acknowledgment openers, action-update constructions, soft-close patterns, gratitude phrases, sign-off variants). Output: `vocabulary.md`.
4. **Punctuation extractor**: reads all staged samples. Measures exclamation rate per 100 words, em-dash rate (should be zero or near-zero), contraction frequency, quote style (curly vs. straight), emoji presence by register. Output: `punctuation.md`.
5. **Format-specific extractor**: reads all staged samples, grouped by inferred format (email, Slack, doc, post). Per format: opener pattern, body shape, close pattern. Notes which formats are present in the corpus and which are missing (skill flags missing ones for the operator to add). Output: `format-tendencies.md`.

Every subagent prompt MUST include:

- The path to the staged samples directory
- The expected output schema as a fenced markdown block matching the corresponding section of the existing `personal.md`
- The privacy rule: **observations only; never quote sample content longer than 5 words; never name people or companies from the samples in the output**
- The "report by index, never by content" instruction (samples are referenced as `001.txt`, not by their text)
- One-sentence statement: this populates a Layer 2 voice file (`personal.md`) that Claude loads for every output the operator's framework produces

### Step 4: Aggregate

Once all subagents return, read the 5 staging files. Surface to the operator in a single chat message:

- **Per-section summary** (one paragraph each: sentence shape, hedging + conviction, vocabulary, punctuation, format tendencies)
- **Conflict callouts** between agents (e.g., punctuation extractor reports high em-dash rate but the do-not.md universal rule bans them; flag the conflict for resolution)
- **Coverage gaps** (formats not present in the corpus, registers under-represented, sample-count warnings)
- **Proposed `personal.md` draft** (compiled into the schema below)

### Step 5: Operator review

Pause for the operator to review the draft. Common edits:

- Tighten the vocabulary section to remove anomalies the operator doesn't recognize ("I never say that, the agent over-indexed on one sample")
- Adjust sign-off variants to match the operator's actual default
- Reconcile any conflict with `do-not.md` (the operator may want to override universal rules in their personal layer, or accept the universal rule and edit their natural pattern)
- Add the "Application notes" section pointing to the correct downstream files (`formats.md`, engagement-layer `voice.md`)

Edit-in-place is fine. The draft lives at `/tmp/operator-voice-bootstrap-{stamp}/personal.md` until commit.

### Step 6: Write the new personal.md

Once the operator accepts the draft:

1. **Quarantine the old file.** `mv Universal/FOLLOW-workflows-and-guides/voice/personal.md _trash/{YYYY-MM-DD}/personal.md` and append a row to `_trash/_manifest.md` per the file-deletion-constraint rules.
2. **Move the new draft into place.** `mv /tmp/operator-voice-bootstrap-{stamp}/personal.md Universal/FOLLOW-workflows-and-guides/voice/personal.md`
3. **Update the file's header note.** Replace any "worked example" disclaimer with: `Regenerated YYYY-MM-DD from {N} writing samples across {formats present}. Replaces the framework author's worked example.`
4. **Append to `Universal/RECORD-decisions/_index.md`:**
   ```
   | {YYYY-MM-DD} | operator-voice-bootstrap completed. {N} samples processed; personal.md regenerated covering {format list}. | Universal | operator-voice-bootstrap skill | (rationale + summary of sample sources in this ledger row) |
   ```
5. **Update `.claude/_setup-state/config.json`** with:
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

   Preserve all other keys in the config. Use the same atomic-write pattern as engagement-bootstrap (`mktemp` + `mv`).

### Step 7: Optional change-protocol sweep

If the new `personal.md` changes voice rules in ways that affect downstream files (for example: the previous personal.md had `Em dashes: zero` and the new one has `Em dashes: moderate`, OR vocabulary preferences flipped on a high-frequency word), surface this to the operator and offer to invoke `change-protocol-sweep` to audit downstream files for affected content.

Default: ask the operator before invoking. The sweep is only needed when voice rules genuinely changed; cosmetic regeneration (same patterns, fresher counts) doesn't warrant a sweep.

### Step 8: Smoke test

Generate a short test output in the new voice (a one-paragraph reply to a hypothetical "thanks for the update" message). Show the operator:

- The output itself
- The voice attestation line: `Voice loaded: do-not + personal + {format} (internal)`. No `:default` suffix on personal.

If the operator confirms the output sounds like them, the regeneration is complete. If not, offer to re-run with edits to the staged draft, or to adjust specific sections of `personal.md` by hand.

### Step 9: Clean up staging

Delete `/tmp/operator-voice-bootstrap-{stamp}/` once the operator accepts the output. The sample files leave no trace outside the operator's original source locations.

## Output schema

The new `personal.md` MUST match the existing section structure so `voice-composition.md`'s loader works without changes. Sections, in order:

1. **Header note** ("Regenerated YYYY-MM-DD from {N} samples...")
2. **§ Voice** (2-3 paragraphs of warmth / register / temperature observations; adjectives that fit + adjectives that don't)
3. **§ Sentence shape** (mean + median + distribution)
4. **§ Hedging + conviction** (overt hedging rate, warmth-offering rate, conditional softener rate, confidence-marker rate, apology rate)
5. **§ Sign-offs** (default + variants + frequency)
6. **§ Common vocabulary** (characteristic words and structural moves)
7. **§ Punctuation and mechanics** (exclamation rate, em-dash rate, contractions, quote style)
8. **§ Format-specific tendencies** (per format observed in the corpus; cross-references to `formats.md`)
9. **§ What the operator avoids naturally** (items from `do-not.md` the operator's own writing already avoids)
10. **Application notes** (4-step composition order pointing at `do-not.md`, this file, `formats.md`, engagement-layer `voice.md`)

The operator's voice content can be totally different from the worked example. The section structure stays identical.

## State-file participation

Same pattern as `engagement-bootstrap-from-urls`. If the `initial-install` orchestrator is active (`.claude/_install-state/state.json` exists with `orchestrator_active: true`), this skill writes its own per-skill block:

```json
{
  "skill_runs": {
    "operator-voice-bootstrap": {
      "last_run_at": "2026-MM-DDTHH:MM:SS",
      "outcome": "success",
      "summary": "120 samples processed across email + Slack + blog; 5 sections populated",
      "invoked_by": "orchestrator"
    }
  }
}
```

Outcome values:
- `success`: 5 subagents returned usable output, draft accepted by operator, `personal.md` committed
- `partial`: some subagents returned low-confidence output (low sample count for their section), but a draft was committed
- `failed`: insufficient samples to produce a draft, or operator rejected the draft outright
- `skipped`: operator declined at Step 1 (no quarantine, no commit)

Use the lock-file convention before any state.json write. Atomic write (`mktemp` + `mv`) for the file itself.

Standalone invocation is still fully supported. If `.claude/_install-state/state.json` does not exist, the skill runs end-to-end without state tracking and updates only `.claude/_setup-state/config.json` (which is owned by this skill, not the orchestrator).

## Hard constraints

- **Privacy: samples stay on device.** No third-party services. No quoting samples in the output file (>5 words). No naming people or companies from the samples.
- **Schema preservation.** The new `personal.md` matches the existing section structure exactly so the voice-composition loader works unchanged.
- **Operator review before commit.** Never overwrite `personal.md` without explicit operator confirmation on the draft.
- **Quarantine, never delete.** The old `personal.md` moves to `_trash/{YYYY-MM-DD}/`. The operator empties the trash via Finder.
- **Minimum sample count.** Below 50 samples, warn loud and offer to defer. Below 20, refuse and ask for more.

## Failure handling

| Failure | Recovery |
|---|---|
| Below 20 samples | Refuse. Ask the operator to gather more. Exit clean. |
| 20-50 samples | Warn. Offer to proceed with a `low-confidence` note in the file header, or defer. |
| One subagent returns no usable output | Re-run that single subagent with a tightened scope. Don't block the other four. |
| Subagent quotes sample content longer than 5 words | Strip the quotes in aggregation. Flag the violation to the operator. |
| Operator rejects the draft outright | Keep the existing `personal.md`. Don't quarantine. Don't commit. Record the rejection in the decisions ledger. |
| State.json lock contention | Retry briefly per the engagement-bootstrap pattern. The `personal.md` write itself is not gated by the lock; only the state.json update is. |
| Operator cancels mid-extraction | Staging files in `/tmp/` are not committed. Existing `personal.md` unchanged. No partial state. |

Per the playbook §"Failure modes" table. Surface each failure to the operator with a recovery option.

## Cross-references

- Spec: `Universal/FOLLOW-workflows-and-guides/playbooks/operator-voice-bootstrap.md`
- Sibling skill (Layer 3): `Universal/RUN-automations/skills/engagement-bootstrap-from-urls/SKILL.md`
- Voice composition rule: `Universal/FOLLOW-workflows-and-guides/playbooks/voice-composition.md`
- Universal voice floor (Layer 1): `Universal/FOLLOW-workflows-and-guides/voice/do-not.md`
- Change-protocol sweep (optional Step 7): `Universal/FOLLOW-workflows-and-guides/playbooks/change-protocol.md`
- File-deletion constraint (Step 6 quarantine): `Universal/READ-references-and-knowledge/concepts/file-deletion-constraint.md`
