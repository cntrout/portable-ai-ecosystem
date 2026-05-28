---
name: process-meeting-transcripts
description: Ingests auto-generated meeting transcripts (Gemini for Google Meet, Otter, Fireflies, Read.ai, Granola, manual paste) from a configured inbox folder. For each file the skill parses metadata, classifies by initiative, files into the right location, generates a summary, extracts action items into the appropriate action-items.md, and marks the file as processed. Source-agnostic. Use daily during active engagement or whenever new transcripts arrive in the inbox.
allowed-tools: Read, Write, Edit, Bash, Glob, Grep
---

# Process Meeting Transcripts

Runtime for the procedure in `Universal/FOLLOW-workflows-and-guides/playbooks/process-meeting-transcripts.md`. Source-agnostic. The playbook is the spec.

## When this skill fires

User wants to process new meeting transcripts that have landed in the inbox folder since the last run.

## Steps

### Step 1: Locate the inbox folder

Default per device:

- **Client device (Gemini via Google Meet):** `~/ai-workspace/automated-notes/`
- **Personal Mac:** typically uses `granola-transcript-workflow.md` instead; if user invokes this skill there, ask which folder

Override path is set per-engagement at `Universal/FOLLOW-workflows-and-guides/transcript-source.md` if that file exists.

Confirm the resolved path with the user before scanning.

### Step 2: Scan for new files

List files in the inbox. For each, check whether a matching marker exists at `{inbox-folder}/_processed/{YYYY-MM-DD}-{slug}.processed`. Skip files with a matching marker.

Surface:

```
Found {N} new transcripts:
  1. {filename} ({size}, {modified-date})
  2. {filename} ({size}, {modified-date})
  ...

Process all? Or specify which?
```

### Step 3: Per-file processing

For each file the user wants to process:

**a. Read and parse.** Read the full transcript. Extract:

- Meeting title (from filename or content)
- Date (from filename, content, or file mtime)
- Attendees (from header or first 10 lines)
- Meeting type (1:1, team sync, customer call, all-hands, working session, kickoff, etc.)

For any missing field that can't be inferred, ask the user. Don't fabricate.

**b. Classify by initiative.** Apply default classification:

- Meeting title or content names a specific initiative → file under that initiative
- Engagement-level (leadership 1:1, all-hands, cross-initiative working session) → file at engagement level
- Ambiguous → ask the user

Check `Universal/FOLLOW-workflows-and-guides/transcript-classification-rules.md` for per-engagement overrides. The file has a table mapping title or attendee patterns to default initiatives. Top-to-bottom, first match wins.

**c. File the transcript.** Initiative-scoped path:

```
Initiatives/{slug}/READ-references-and-knowledge/meetings-and-transcripts/{YYYY-MM-DD - Meeting Title}.md
```

Engagement-level path:

```
Universal/READ-references-and-knowledge/meetings-and-transcripts/{YYYY-MM-DD - Meeting Title}.md
```

Use the vault file convention from root `AGENTS.md`: `YYYY-MM-DD - Descriptive Title.md`.

**d. Generate summary.** Two-pass output as a sibling file `{filename}.summary.md`:

- **One-paragraph overview** (~50-80 words): what the meeting covered, who was there, the key outcome
- **Structured bullets** for: decisions made, open questions, action items, key context worth remembering

**e. Extract action items.** Append to the right `action-items.md`:

- Initiative-scoped: `Initiatives/{slug}/action-items.md`
- Engagement-level: `Universal/action-items.md` (create if first time; folder-creation rules require a parent README update if so)

Format per item:

```
- [ ] {action} ({owner}) {due-date-if-any} (from `{transcript-path}`)
```

Default owner is the operator if not clear; flag for confirmation.

**f. Glossary check.** Identify any new company-specific terms that surfaced (product names, customer names, internal acronyms). Surface to the user BEFORE adding to glossary:

```
New terms found in {transcript-path}:
  1. "{term}": appears {N} times. Context: "...{quoted line}..."

Add to glossary? [Y/n/edit]
```

Don't auto-add.

**g. Mark as processed.** Create the marker:

```bash
touch {inbox-folder}/_processed/{YYYY-MM-DD}-{slug}.processed
```

Empty file. Its presence prevents re-processing on the next run.

### Step 4: Report results

Per file:

```
{filename}:
  Filed to: {path}
  Summary at: {path}.summary.md
  Action items extracted: {N} → {action-items.md path}
  Glossary terms surfaced: {N} (pending user review)
  New initiative suggested: {slug if any}
```

Aggregate at the end:

```
Processed {N} transcripts. {M} action items added. {K} glossary terms pending review.
```

### Step 5: Optional follow-up prompts

Ask the user:

- Were any glossary terms missed? They can add now or later.
- Were any action items mis-classified to the wrong initiative? They can move now or later.
- Want a summary digest of all processed meetings posted to a single roll-up file?

## Behavior constraints

- Never overwrite a previously-processed transcript without confirming via content hash
- Never auto-add glossary terms; always ask
- Never fabricate attendees, dates, or meeting type; ask if not inferable
- Mark processed only after all sub-steps complete successfully

## Failure handling

Per `process-meeting-transcripts.md` §"Failure modes". Key cases:

- File can't be parsed (binary, .gdoc pointer): ask user to manually export to .md or .txt
- Classification ambiguous and no rule helps: ask user; offer to update the classification rules file
- Inbox folder doesn't exist or isn't syncing: surface as setup error pointing at the install runbook
- Duplicate processing detected: ask user before overwriting

## Cross-references

- Spec: `Universal/FOLLOW-workflows-and-guides/playbooks/process-meeting-transcripts.md`
- Parent: `Universal/FOLLOW-workflows-and-guides/playbooks/portable-ai-ecosystem.md`
- Folder rules: `Universal/FOLLOW-workflows-and-guides/playbooks/folder-creation-rules.md`
- Cowork-era predecessor (personal Mac): `granola-transcript-workflow.md`
- Classification overrides: `Universal/FOLLOW-workflows-and-guides/transcript-classification-rules.md` (per-engagement, if exists)
