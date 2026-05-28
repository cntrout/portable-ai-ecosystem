---
type: playbook
last_reviewed: 2026-05-27
sync_trigger: 2026-05-27-deferred-items-batch
depends-on:
  - playbook:portable-ai-ecosystem
  - playbook:change-protocol
---

# External Tool Approval Playbook

Procedure for vetting any third-party tool before requesting client IT/InfoSec approval. Covers MCP servers, Claude Code skills and plugins from public sources, desktop applications (Obsidian, Smart Connections, etc.), and CLI utilities (ripgrep, jq, fzf, etc.).

Dual audience. The "Submission template" section is what the operator fills out and sends to client IT. The "Vetting checklist" section is what client IT can use to evaluate the request. Designed so both sides see the same shape and the back-and-forth is minimal.

## TL;DR

Before asking client IT to approve anything, fill out the Submission template below. It captures: vendor, source, data flows, network endpoints, OAuth scopes (if any), local-vs-cloud execution, audit trail availability, equivalent alternatives if rejected. Submit one ticket per tool. Once approved, record the decision in `Universal/RECORD-decisions/_index.md`. Re-vet on major version bumps or on any change in data flow.

## When to use this

- Before installing any tool not already on the device by IT default (and not on the "no-ask-needed" list below)
- Before activating any MCP server in Claude Code
- Before installing any Claude Code skill or plugin from a public source (GitHub, plugin marketplace, third-party authors)
- Before installing any desktop app (Obsidian, Smart Connections, note-taking apps, etc.)
- Before installing any CLI utility (Homebrew packages, `npm install -g`, `pip install`, language-specific tooling)
- On any major version bump of an already-approved tool that changes data flow, network endpoints, or scope
- When a tool's vendor gets acquired, changes ownership, or significantly changes its privacy policy

## What does NOT need approval

A tiny floor of things that are already on most managed devices by default:

- Terminal (Terminal.app or iTerm2 if iTerm2 is already approved)
- `git` (if standard distribution)
- `man`, `grep`, `find`, `awk`, `sed`, `curl`, `wget`, `ssh`, `scp`, and other POSIX standard utilities
- Editor of choice if pre-approved (nano, vim, VS Code if approved)
- Anthropic Claude Code itself, once it's been approved as part of the device baseline

Everything else gets the playbook.

## Scope: what counts as an "external tool"

Five categories, each with its own vetting data points.

### Category 1: MCP servers

Code that runs on the device and exposes tools / resources / prompts to Claude Code. May be local-only or may make outbound network requests.

Vetting data points needed:

- Vendor / publisher / author
- Source repo (GitHub URL or equivalent)
- Distribution method (npm, brew, manual clone, vendor binary, etc.)
- Local-only or outbound network access
- If outbound: every endpoint contacted and what data is sent
- If OAuth-based: every scope requested and what each scope grants
- Authentication storage (Keychain, file on disk, environment variable, etc.)
- Telemetry: any usage data sent to the vendor or third parties
- Update mechanism: does it auto-update, ask, or stay frozen
- Equivalent local-only alternative if rejected

### Category 2: Claude Code skills and plugins from public sources

Skills (`.claude/skills/{name}/SKILL.md`) or plugins (a bundled set of skills) authored by someone other than the operator or Anthropic-blessed sources.

Vetting data points:

- Author (and whether the operator personally vouches for them)
- Source repo
- What the skill does (one-line summary)
- What tools it calls (Read, Write, Edit, Bash, WebFetch, WebSearch, MCPs, etc.) and what each call enables
- Whether it ships executable scripts (and if so, what they do)
- Whether it makes network calls
- Whether it stores or reads any local state
- Whether it integrates with any MCP (which one)
- Update mechanism

### Category 3: Desktop applications

Examples: Obsidian, Smart Connections, Drive for Desktop, any text editor or note app.

Vetting data points:

- Vendor / publisher
- Distribution (App Store, vendor website, Homebrew, .pkg installer)
- Code-signing status (Apple Developer ID, notarization)
- Outbound network endpoints (telemetry, sync, license check, update)
- Local data access (which folders the app reads / writes by default)
- Account / login required (and which account: personal vs. company)
- Cloud sync component (yes / no; what's synced)
- Plugin / extension surface (does it have third-party plugins; are those individually vetted)
- Update mechanism (auto / manual / disabled)

### Category 4: CLI utilities

Examples: ripgrep, jq, fzf, htop, tree, watchman, etc.

Vetting data points:

- Vendor / publisher
- Distribution (Homebrew, MacPorts, vendor binary, source build)
- Sandboxed or full-system access (most CLI tools are full-access by default; note any that aren't)
- Outbound network calls (most have none; flag any that do)
- Bundled telemetry (most have none; flag any that do)

### Category 5: Browser extensions

Examples: a Claude Code companion extension if one exists, Drive integration extensions, etc.

Vetting data points:

- Publisher
- Permissions requested (read this site, modify all data, history, etc.)
- Update mechanism
- Telemetry

## Submission template

Copy this template per tool and fill in. Paste into the IT ticketing system or attach to the approval email.

```markdown
# Tool approval request: {Tool name}

**Requester:** {Operator name}
**Date:** YYYY-MM-DD
**Category:** [MCP server / Claude Code skill or plugin / Desktop application / CLI utility / Browser extension]
**Tool name:** {name}
**Version requested:** {version}

## What this is and why I'm asking

{2-4 sentences: what the tool does, why it's useful for the work, what's missing without it.}

## Vendor

- **Publisher:** {name}
- **Source repo or download URL:** {URL}
- **Code-signing / notarization status:** {if relevant}
- **Personal-vouch:** [Yes / No / N/A] (Yes = I know the author personally; No = public open source)

## Data flow

- **Outbound network endpoints:** {list every endpoint and what's sent}
- **Local data access:** {which folders the tool reads / writes}
- **Account or login required:** {none / personal account / client account}
- **OAuth scopes (if any):** {list each scope and what it grants}
- **Cloud sync component:** {none / what's synced / where}
- **Telemetry:** {none / what's collected and where it's sent}

## Audit trail

- **Vendor-side audit log available:** {yes (location) / no}
- **Local logs the tool produces:** {paths}

## Update mechanism

{Auto / asks first / manual / vendor-controlled. Can it be disabled?}

## Equivalent if rejected

{The simplest substitute that doesn't require this tool. If the answer is "we can't do this thing at all," say so explicitly.}

## Re-vet triggers

{Conditions that would make me re-submit: major version bump, change in data flow, vendor acquisition, etc.}

## Reference

This submission follows `Universal/FOLLOW-workflows-and-guides/playbooks/external-tool-approval.md` in the AI ecosystem framework.
```

## Vetting checklist (for the approver)

Client IT can apply this rubric. Each item is a yes/no with notes:

### Identity and provenance

- [ ] Vendor is identifiable, has a public website or repo, has been around long enough to assess
- [ ] Source code is available (open source) OR the vendor is a trusted commercial entity
- [ ] No known recent compromise, breach, or supply-chain incident
- [ ] Distribution channel is the official one (no mirrors, no unsigned binaries unless the source is built from source)

### Data flow

- [ ] Network endpoints are documented and reasonable for what the tool does
- [ ] No data sent to endpoints that aren't on the documented list
- [ ] OAuth scopes (if any) are minimal-necessary, not over-broad
- [ ] Tool does NOT exfiltrate file contents, clipboard, screen captures, or keystrokes unless that's explicitly its function (in which case is the function approved?)
- [ ] Tool does NOT call home with telemetry that includes user content (anonymous usage counters are fine; content is not)

### Local access

- [ ] Tool reads / writes only the folders required for its function
- [ ] Tool does NOT request elevated privileges (sudo, admin) unless absolutely required
- [ ] Tool does NOT install kernel extensions or system-wide daemons unless that's its purpose and the purpose is approved

### Update and supply-chain

- [ ] Update mechanism is auditable (signed releases, locked versions, or a manual update flow)
- [ ] Auto-update can be disabled if needed
- [ ] If the tool has third-party plugin / extension surface, plugin install is separately controllable

### MCP-specific

- [ ] MCP server runs locally, not as a remote service hosted by the vendor (unless explicitly approved as a hosted service)
- [ ] MCP tools have clear, scoped functions (no "execute arbitrary code" tools that aren't sandboxed)
- [ ] MCP doesn't bundle credentials or API keys for other services without explicit configuration

### Skill / plugin-specific

- [ ] Skill source code reviewed; no obfuscated logic
- [ ] Tools the skill calls match its stated function
- [ ] No network calls beyond what's stated
- [ ] No write access to folders outside the working folder unless stated

## Decision record

Whether approved or rejected, record the outcome in `Universal/RECORD-decisions/_index.md`. Format:

| Date | Decision | Scope | Triggered by | Record |
|------|----------|-------|--------------|--------|
| YYYY-MM-DD | {Tool name} {version} approved / rejected for {category}. Conditions: {any}. | Universal | external-tool-approval submission YYYY-MM-DD | {link to the original submission, IT ticket ID if available} |

If approved with conditions (e.g., "approved but only for the duration of the {X} project"), record the conditions explicitly. Future re-vets reference this row.

## Re-vetting

A previously-approved tool requires re-submission when:

- A major version is released (semver major bump, or vendor-declared "major release")
- The vendor changes hands (acquisition, sale, etc.)
- The privacy policy or terms of service materially change
- New data flows are added (a new endpoint, a new OAuth scope, a new local-folder default)
- The IT side asks for a periodic refresh (quarterly, annually, etc.)
- Conditions of the original approval expire (e.g., project-bound approvals)

The re-submission uses the same template and references the original approval's ledger row.

## Approved-tool registry

Once approved, the tool gets a row in a per-engagement approved-tools registry:

```
Universal/READ-references-and-knowledge/approved-tools.md
```

Format:

| Tool | Category | Version approved | Approved on | Conditions | Ledger row |
|---|---|---|---|---|---|
| Claude Code | Anthropic CLI | {version} | YYYY-MM-DD | None | [link] |
| git | CLI utility | (standard) | YYYY-MM-DD | None | [link] |
| {tool} | {category} | {version} | YYYY-MM-DD | {conditions} | [link] |

This file is the single source of truth for "what's allowed on the device." Reference it before any install attempt.

## Examples for a typical day-1

Likely first submissions on a new client device, framed against this template:

- **Claude Code** (Anthropic CLI). Already device-baseline, but worth a confirmation row in the registry.
- **`git`** (standard distribution). Same.
- **Drive for Desktop** (Google). Category: desktop app. Justified by `process-meeting-transcripts.md` day-1 workflow.
- **Obsidian** (Obsidian.md). Category: desktop app. Justified if the operator wants the visual editor on the client device; otherwise plain text in Terminal works.
- **Smart Connections** (Obsidian plugin). Category: desktop app plugin. Justified by semantic search in the vault; depends on Obsidian approval first.
- **`ripgrep`** (Homebrew). Category: CLI utility. Justified by the sanitization scanner.
- **`jq`** (Homebrew). Category: CLI utility. Justified by JSON parsing in scripts.
- **An MCP server for Google Drive** (Anthropic-blessed or community). Category: MCP. Justified by automating `process-meeting-transcripts.md`.

Each one gets its own submission per the template above. Don't bundle.

## Cross-references

- Parent playbook: `portable-ai-ecosystem.md`
- Install runbook for the client device, which references day-1 approvals: `portable-ai-ecosystem.md` §"Install runbook"
- Decisions ledger row format: `change-protocol.md` §"Decisions ledger interaction"
- Approved-tools registry lives at: `Universal/READ-references-and-knowledge/approved-tools.md`

*History: [Universal/RECORD-decisions/_index.md](../../RECORD-decisions/_index.md)*
