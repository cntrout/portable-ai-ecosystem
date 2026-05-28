---
type: playbook
last_reviewed: 2026-05-27
sync_trigger: 2026-05-27-deferred-items-batch
depends-on:
  - playbook:initiative-kickoff
  - playbook:folder-creation-rules
  - playbook:change-protocol
  - playbook:portable-ai-ecosystem
  - playbook:external-tool-approval
---

# Process Meeting Transcripts Playbook

Generic procedure for ingesting auto-generated meeting transcripts and notes from any source (Gemini for Google Meet, Otter, Fireflies, Read.ai, Granola, or manual paste) into the AI ecosystem. Source-agnostic by design so it works on locked-down client devices and on any other device the operator runs.

## TL;DR

The playbook is source-agnostic. Configure the **inbox folder** at install time (where transcripts arrive). For each new file: read, classify by initiative, file into the right location, generate a summary, extract action items, append to the initiative's `action-items.md`. Day-1 runs manually via prompt; v2 runs automatically once a Drive MCP or similar gets IT-approved.

## When to run this

- Daily during active engagement, after the first morning meeting block
- Whenever new transcripts have arrived in the inbox folder
- When closing out a day before drafting handoffs or status updates

## Source configuration

The playbook reads from one local folder, configured per device.

### Client device with Google Drive sync (Gemini via Google Meet)

Client Drive auto-saves Gemini-generated transcripts. The operator adds shortcuts to those files into a single centralized folder in a personal Drive (path set at install time). Drive for Desktop on the client device (if approved by client IT, see `external-tool-approval.md`) syncs that folder locally.

Recommended path:
```
~/Google Drive/My Drive/automated-notes/
```

If Drive for Desktop is not approved, the day-1 fallback is manual paste:

1. Open the Gemini-generated doc in Drive web
2. Copy the content
3. Paste into a new file at `~/ai-workspace/_inbox/transcripts/{YYYY-MM-DD - Meeting Title}.md`
4. Invoke this playbook

### Other sources

Otter, Fireflies, Read.ai, Granola, and direct manual paste all work the same way: configure the inbox folder where the source drops files (or where the operator pastes them), and the processing logic below applies. Only the file-detection regex and metadata-extraction need source-specific tweaks. Add a section here when a new auto-transcript source comes into the workflow.

## File detection

Default: any new file in the configured inbox folder.

Identification of new vs already-processed: each processed file gets a sibling marker at `_processed/{YYYY-MM-DD}-{slug}.processed` (empty file). On a given run, the playbook scans the inbox, ignores anything with a matching marker, and processes the rest.

If file naming is structured (Gemini's default is `Meeting Title YYYY-MM-DD`), parse the title and date from the filename. If not, parse from the file contents.

## Processing procedure (per file)

For each unprocessed transcript:

### 1. Read and parse

Read the full transcript. Identify:

- Meeting title
- Date
- Attendees (extract from the header or first 10 lines; some sources include them, some don't)
- Meeting type (1:1, team sync, customer call, all-hands, working session, kickoff, etc.)

If any field is missing and not inferable, surface a clarifying question in chat before proceeding.

### 2. Classify by initiative

Default classification logic:

- If the meeting title or content names a specific initiative (e.g., "v2.1 Widget kickoff"), file under that initiative
- If the meeting is engagement-level (a leadership 1:1, an all-hands, a cross-initiative working session), file at the engagement level (`READ-references-and-knowledge/meetings-and-transcripts/`)
- If ambiguous, ask the operator

The classification rule can be refined per engagement. See "Classification overrides" below.

### 3. File the transcript

File the raw transcript at the classified path:

```
Initiatives/{slug}/READ-references-and-knowledge/meetings-and-transcripts/{YYYY-MM-DD - Meeting Title}.md
```

OR, for engagement-level meetings:

```
Universal/READ-references-and-knowledge/meetings-and-transcripts/{YYYY-MM-DD - Meeting Title}.md
```

Filename convention: `YYYY-MM-DD - Meeting Title.md` per the vault file convention in root `AGENTS.md`.

### 4. Generate a summary

Two-pass summary:

- **One-paragraph overview** (~50-80 words): what the meeting was about, who was there, the key outcome
- **Structured bullets** for: decisions made, open questions, action items, key context worth remembering

Save the summary as a sibling file:

```
{YYYY-MM-DD - Meeting Title}.summary.md
```

### 5. Extract action items

For every action item identified:

- Owner (default: the operator if unclear)
- Action
- Due date if mentioned, otherwise blank
- Source: link to the transcript file

Append to the appropriate `action-items.md`:

- Initiative-scoped: `Initiatives/{slug}/action-items.md`
- Engagement-level: a single `Universal/action-items.md` (create if first time; per folder-creation-rules, add `_index.md` reference to its parent)

Action item format:
```
- [ ] {action} ({owner}) {due-date-if-any} (from `{transcript-path}`)
```

### 6. Update glossary if new terms surfaced

If the transcript introduces new company-specific terms (product names, customer names, internal acronyms), surface them for the operator to confirm and add to `Universal/READ-references-and-knowledge/glossary.md` (engagement-level) or initiative-scoped glossary if one exists.

Don't auto-add. Ask the operator first.

### 7. Mark as processed

Create the processed marker:

```
{inbox-folder}/_processed/{YYYY-MM-DD}-{slug}.processed
```

Empty file. Its presence prevents re-processing on the next run.

## Classification overrides

Per-engagement overrides go in the engagement layer at:

```
Universal/FOLLOW-workflows-and-guides/transcript-classification-rules.md
```

Format: a table mapping meeting-title patterns or attendee patterns to default initiatives. Example:

| Pattern | Default initiative |
|---|---|
| Title contains "Widget" | `v2-1-widget` |
| Attendees include `{partner-customer-rep}` | `partner-integration` |
| Meeting is recurring "Daily Standup" | `cross-cutting` (engagement-level) |

Patterns are evaluated top-to-bottom. First match wins. Without overrides, the default classification logic applies.

## Invocation

### Manual (day-1, no MCP)

In a `claude` session inside the working folder:

> "Process new meeting transcripts in `~/Google Drive/My Drive/automated-notes/`. Use the playbook at `Universal/FOLLOW-workflows-and-guides/playbooks/process-meeting-transcripts.md`."

Claude reads the playbook, scans the inbox, processes each new file, surfaces classification ambiguities for confirmation, and reports a per-file disposition at the end.

### Automated (v2, after IT approves the MCP layer)

Once a Drive MCP or a `launchd` user agent is approved by client IT:

- **Drive MCP path:** a scheduled task fires every N hours, lists new files, processes them.
- **launchd path:** a user agent runs `claude -p "process new meeting transcripts ..."` non-interactively. The launchd headless `claude -p` pattern is empirically validated; see `portable-ai-ecosystem.md` §"Open questions" for the test record.

Both paths depend on client-side IT approval of the underlying tool (MCP or launchd workflow).

## Failure modes

| Failure | Recovery |
|---|---|
| File can't be parsed (binary, .gdoc pointer, encrypted) | Ask the operator to manually export the file to .md or .txt and re-run |
| Classification is ambiguous and the override table doesn't help | Ask the operator; record the decision in the classification-rules file |
| Action items have no clear owner | Default to the operator; flag for confirmation |
| Inbox folder doesn't exist or isn't syncing | Surface as a setup error, not a processing failure. Reference the install runbook |
| Duplicate processing (marker missing or deleted) | Detect duplicate via content hash; ask the operator before overwriting |

## Cross-references

- Parent playbook: `portable-ai-ecosystem.md`
- Engagement-level bootstrap: `engagement-bootstrap-from-urls.md`
- Initiative kickoff (creates the per-initiative folders this playbook files into): `initiative-kickoff.md`
- External tool approval (covers Drive for Desktop, Drive MCP): `external-tool-approval.md`
- Folder creation rules (folders this playbook may create): `folder-creation-rules.md`

*History: [Universal/RECORD-decisions/_index.md](../../RECORD-decisions/_index.md)*
