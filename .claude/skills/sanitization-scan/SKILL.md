---
name: sanitization-scan
description: Scans a staging directory before first commit of the portable-ai-ecosystem repo for past-client signal, regulatory tokens, PII, internal financial figures, named individuals, customer-name leaks, and prompt-injection-style strings. Runs ripgrep against ~25 patterns, surfaces flagged content per-file for user disposition (accept/redact/drop/escalate), produces a sanitization manifest committed with the repo as audit trail. Use before any `git init` or push.
allowed-tools: Read, Write, Edit, Bash, Glob, Grep
---

# Sanitization Scan

Runtime for the sanitization protocol in `Universal/FOLLOW-workflows-and-guides/playbooks/portable-ai-ecosystem.md` §"Sanitization". The 25-pattern spec is inlined in step 3 below; no external load required.

## When this skill fires

The user has staged the portable-ai-ecosystem repo content in a directory outside their working vault and wants to scan it before the first commit. The skill is also re-invocable for any subsequent commit that adds substantial new content.

## Steps

### Step 1: Confirm the staging path

Ask the user for the absolute path to the staging directory. Default: `~/portable-ai-ecosystem-staging/`.

Verify the directory exists with `ls -la {path}`. Confirm with the user that this is the exact path to scan. Abort if the user backs out.

### Step 2: Verify `rg` is available

Run `which rg` to confirm ripgrep is installed. If not, surface install instructions (`brew install ripgrep` on macOS) and pause until the user confirms ripgrep is available. The skill does not auto-install.

### Step 3: Build the pattern set

This skill is a **template**. The operator supplies the actual list of past-client names, past-engagement names, and other engagement-specific tokens to flag, either at install time (saved to a local config file outside the repo) or interactively per-scan. The skill source ships with placeholders, never with real names baked in.

Apply the 25-pattern spec below. Prompt the operator for the engagement-specific values where needed. Categories:

- **Past-client names:** `{past-client-name-1}`, `{past-client-name-2}`, ... (the operator's list of past-client and past-engagement names, plus any others surfaced by audit). Ask the operator to supply this list before scanning; do not infer or remember names across runs.
- **Named individuals from past engagements:** extracted from `Universal/READ-references-and-knowledge/entities/`, handoffs, and decisions ledger entries pre-dating the engagement transition
- **Regulatory tokens:** PCI, PSD2, GDPR, GLBA, CFPB, SOC 2, HIPAA, KYC, AML
- **Customer/partner names** known to be confidential (allow-list per engagement)
- **Internal financial figures:** dollar amounts above a threshold the user sets, deal values
- **Email addresses:** any `@` patterns matching internal or past-client domains
- **Phone numbers:** US and international patterns
- **Confidentiality markers:** "internal only", "confidential", "do not share", "NDA"
- **Prompt-injection-style strings:** "ignore previous", "system:", "you are now", "disregard"
- **Past-client domains:** `{past-client-domain-1}`, `{past-client-domain-2}`, ... (the operator's list of past-client domain names). Ask the operator to supply this list alongside the past-client name list.
- **Working-doc titles** that name a past client
- **Date-stamped internal events** referencing past engagements

Surface the full pattern set to the user, including the operator-supplied values for the templated categories. Allow add/remove before scanning.

### Step 4: Run the scan

For each pattern, run:

```bash
rg -n --no-heading -e '{pattern}' {staging-dir} --glob '!_sanitization-staging/**'
```

Concatenate all matches into `{staging-dir}/_sanitization-staging/flagged.tsv`:

```
file_path<TAB>line_number<TAB>pattern<TAB>matched_content<TAB>category
```

Create `_sanitization-staging/` directory if it does not exist.

### Step 5: Present to the user, file by file

Read the TSV. Group findings by file. Iterate through files in order:

```
File 1/N: {path}
{count} matches:
  Line 12: "{matched content}" (category: past-client)
  Line 47: "{matched content}" (category: PII)
  Line 89: "{matched content}" (category: confidentiality-marker)

Disposition? [A]ccept / [R]edact / [D]rop / [E]scalate
```

Per-file dispositions:

- **ACCEPT**: match is a false positive or acceptable in context; file unchanged
- **REDACT**: user provides replacement text or asks Claude to propose one; file edited in place
- **DROP**: file removed from staging entirely; moved to `_sanitization-staging/_dropped/{relative-path}` for audit
- **ESCALATE**: flagged for human review later; Claude documents the concern, file stays for now

For REDACT, show the proposed replacement before applying. Default proposal: replace the matched substring with a generic placeholder matching the category (e.g., `{past client A}`, `{regulated token}`, `{deal figure}`).

### Step 6: Apply dispositions

Execute the user's decisions:

- REDACT: `Edit` the file, save, log the change to the manifest
- DROP: `mv` to `{staging-dir}/_sanitization-staging/_dropped/{relative-path}`
- ACCEPT and ESCALATE: log the decision; no file change

### Step 7: Write the sanitization manifest

Generate `{staging-dir}/_sanitization-manifest.md`:

```yaml
---
type: sanitization-manifest
date: {YYYY-MM-DD}
scanner-version: 1
---
```

Body sections:

- **Patterns used** (verbatim list from Step 3, with any user additions/removals)
- **Total flagged matches** with counts per category
- **Per-file dispositions** in tabular form: file path | matches | disposition | notes
- **Files dropped** with their relative paths and one-line reason
- **Escalated items** flagged for human review
- **Verification re-scan result** (filled in at Step 8)
- **Operator notes** (anything unusual)

This manifest commits with the repo as the public audit trail.

### Step 8: Verification re-scan

Run the same scan again against `{staging-dir}` minus `_sanitization-staging/`. Expected: zero matches.

If zero matches → write "VERIFIED PASS" into the manifest and proceed.

If non-zero matches → present the remaining matches to the user, loop back to Step 5 for those files. Document the iteration in the manifest.

### Step 9: Manual spot-check prompt

After verification PASS, surface:

> Sanitization scan PASSED. Recommended next step: manually spot-check the top-20 files most likely to retain past-client signal (entities, handoffs, exemplars, ledgers, voice files). Want me to enumerate them?

If yes, list the highest-risk files and pause per file for the user's read-and-confirm.

### Step 10: Append a ledger row

In `Universal/RECORD-decisions/_index.md`:

```
| {YYYY-MM-DD} | Sanitization scan completed against {staging-dir}. {N} files scanned, {M} matches flagged, dispositions: accept {a} / redact {r} / drop {d} / escalate {e}. Verification re-scan: PASS. | Universal | sanitization-scan skill | [[{staging-dir}/_sanitization-manifest.md]] |
```

## Behavior constraints

- Never auto-redact without showing the proposed replacement first
- Never auto-drop a file without confirmation
- Never modify files outside the staging directory
- Preserve the `_sanitization-staging/` audit trail even after the repo commits

## Cross-references

- Spec: `Universal/FOLLOW-workflows-and-guides/playbooks/portable-ai-ecosystem.md` §"Sanitization"
- Audit trail format: `{staging-dir}/_sanitization-manifest.md`
- Companion skill that runs before this one: `engagement-bootstrap-from-urls`
