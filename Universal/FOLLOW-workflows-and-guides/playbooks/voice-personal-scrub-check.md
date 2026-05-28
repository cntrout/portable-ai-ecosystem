---
type: playbook
last_reviewed: null
---

# Voice Personal-File Scrub Check

One-shot verification that the shipped `Universal/FOLLOW-workflows-and-guides/voice/personal.md` file is free of any operator-identifying leakage from its source-of-truth derivation. Run this once at first install if the operator wants belt-and-suspenders confirmation that the framework's seed `personal.md` is publishable on this device, or after any edit that adds new voice content to the file.

## When to run this

- On first install, if the operator wants to confirm the shipped `personal.md` is clean before customizing it.
- After any future edit that pulls voice content from a personal source (emails, sales transcripts, chat history) into `personal.md`.
- Before publishing or sharing a vault snapshot that includes the voice files.

Skip this playbook if the operator is fine trusting the upstream framework distribution as already-scrubbed and intends to immediately overwrite `personal.md` with their own voice content.

## What the check looks for

The check runs the same 25-pattern ripgrep scan that `sanitization-scan` uses, against `Universal/FOLLOW-workflows-and-guides/voice/personal.md` only. The patterns cover:

- Specific email addresses or domains tied to past engagements
- Named people from past engagements (entity-page references)
- Past-client company names or product names
- Internal codenames that should not ship publicly
- Slack channel names, internal URLs, or tool-specific identifiers
- Any operator-specific identifier the framework should not bake in

The full pattern set lives in `Universal/RUN-automations/skills/sanitization-scan/SKILL.md`.

## Procedure

1. Open a terminal at the workspace root.
2. Run the sanitization-scan skill scoped to the voice file:

   ```bash
   rg -f Universal/RUN-automations/skills/sanitization-scan/patterns.txt \
      Universal/FOLLOW-workflows-and-guides/voice/personal.md
   ```

3. Review every match. Each match is a candidate leak. For each one:
   - If the match is a false positive (the term appears in a generic sense, not as an operator-identifier), note it and move on.
   - If the match is a real leak, replace it with a placeholder or remove it. Re-run the scan.
4. The check passes when ripgrep returns zero matches.

## What to do if matches surface

Decide per match: scrub, generalize, or accept-with-justification. Record the decision in `Universal/RECORD-decisions/_index.md` if the match is non-obvious and might recur in future edits. Scrubs are usually one-line edits replacing a specific name or address with a placeholder like `{operator-email}` or removing the sentence entirely.

## Cross-references

- `Universal/RUN-automations/skills/sanitization-scan/SKILL.md`: the canonical 25-pattern scanner; this playbook is a scoped invocation of it.
- `Universal/FOLLOW-workflows-and-guides/voice/personal.md`: the file under check.
- `Universal/FOLLOW-workflows-and-guides/playbooks/voice-composition.md`: the four-step voice composition rule that loads `personal.md` at runtime.

## Lifecycle stance

One-shot. This playbook is not on a cadence; the operator runs it at install time and again after any future content addition to `personal.md`. The framework upstream distribution is expected to ship a clean `personal.md`, but this playbook gives the operator a self-serve way to verify.
