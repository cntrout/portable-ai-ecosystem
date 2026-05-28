---
type: config
last_reviewed: null
---

# Meeting Transcript Inbox Configuration

Configuration contract for the `process-meeting-transcripts` playbook. This file describes where transcripts arrive on this device and how the playbook should detect, identify, and route new files. The playbook reads this config at runtime to stay source-agnostic.

The playbook itself lives at `Universal/FOLLOW-workflows-and-guides/playbooks/process-meeting-transcripts.md` and degrades to manual paste when no inbox is configured.

## When to fill this in

On first install, leave this file unconfigured if no meeting source is wired up yet. The playbook will degrade to manual paste, which still works. Configure this file once a meeting source (Gemini for Google Meet via Drive sync, Otter, Fireflies, Read.ai, Granola, or any other auto-transcript source) is approved and writing files to a stable local folder.

## Configuration fields

Fill in the fields below. The playbook reads each by name.

### `inbox_path`

Absolute path to the folder where new transcripts arrive on this device. The playbook scans this folder on each run.

Examples by source:

- **Gemini via Google Drive sync:** `~/Google Drive/My Drive/automated-notes/`
- **Otter desktop export:** `~/Documents/Otter/exports/`
- **Fireflies via Slack export:** `~/Documents/Fireflies-inbox/`
- **Manual paste fallback:** `~/ai-workspace/_inbox/transcripts/`

Pick one and fill it in below.

```yaml
inbox_path: ""
```

### `processed_marker_path`

Where the playbook writes empty marker files to remember which inbox files it has already processed. Defaults to `_processed/` inside the inbox folder if not set.

```yaml
processed_marker_path: ""
```

### `source_type`

Identifier for the source format. The playbook uses this to pick the right parser for file detection and metadata extraction. Supported values: `gemini`, `otter`, `fireflies`, `read-ai`, `granola`, `manual-paste`.

```yaml
source_type: "manual-paste"
```

### `filename_pattern`

Regex or glob that identifies a valid transcript file in the inbox. Defaults to `*.md` or `*.txt` for manual paste; structured sources use source-specific patterns.

```yaml
filename_pattern: "*.md"
```

### `default_initiative`

Slug of the initiative to file transcripts into when classification is ambiguous. The playbook still runs classification; this is only the fallback.

```yaml
default_initiative: ""
```

## Activation

Once filled in, invoke the playbook by prompt, by running `/wire-hooks-and-tasks` to load a launchd plist on a cadence (the operator authors the per-task plist by hand until v1.3 ships ready-made templates at `Universal/RUN-automations/scheduled-tasks/process-meeting-transcripts/`), or by any other manual cadence the operator prefers. The playbook validates this config before running and reports any missing fields as a degraded-mode warning rather than an error.

## What this file does not configure

- The skill itself. The `process-meeting-transcripts` playbook is source-agnostic by design and lives at `Universal/FOLLOW-workflows-and-guides/playbooks/process-meeting-transcripts.md`.
- The meeting MCP (Granola, Otter, etc.) installation. Source approval and connection go through `Universal/FOLLOW-workflows-and-guides/playbooks/external-tool-approval.md`.
- The cadence (daily, hourly, on-demand). Cadence lives in `Universal/RUN-automations/scheduled-tasks/process-meeting-transcripts/` once scheduled.

## Cross-references

- `Universal/FOLLOW-workflows-and-guides/playbooks/process-meeting-transcripts.md`: the playbook that reads this config.
- `Universal/FOLLOW-workflows-and-guides/playbooks/external-tool-approval.md`: the gate for connecting a meeting MCP.
- `Universal/RUN-automations/scheduled-tasks/README.md`: the cadence wiring once a source is configured.

---

*Empty config on first install. The playbook degrades to manual paste until this file is populated.*
