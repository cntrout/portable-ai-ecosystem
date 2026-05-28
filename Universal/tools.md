# Connected Tools

External tools the framework can reach via MCP connectors or direct integration. This file is the canonical catalog that the `initial-install` skill, the `external-tool-approval` playbook, and per-engagement bootstrapping all reference. Read this first when you want to know what the framework expects on a fresh machine, what is genuinely required versus optional, and how each MCP server lands behind an approval gate.

The catalog is organized in tiers. Tier 0 is the minimum without which Claude Code cannot run the framework at all. Tier 1 brings the operator to daily-experience parity with the reference setup. Tier 2 is everything else worth installing if the engagement calls for it. The MCP catalog at the bottom lists Model Context Protocol servers the framework knows how to wire up. Every MCP ships disabled by default and activates only after the operator routes it through `external-tool-approval.md`.

Install commands live here for convenience, but the `initial-install` skill is the source of truth for procedural ordering, idempotency checks, and IT-approval handoffs. Treat this file as the reference shelf, not the runbook.

---

## Tier 0: Required floor

Five tools. Without all five, nothing in the framework works. The `initial-install` skill verifies each one before doing anything else and blocks until any missing entry is resolved.

### Claude Code

- **Vendor:** Anthropic
- **Purpose:** Primary AI runtime. Every skill, hook, playbook, and command in the framework runs through it.
- **Install command:** `npm install -g @anthropic-ai/claude-code`
- **Verify command:** `claude --version`
- **Network endpoints:** `api.anthropic.com:443`
- **Optional:** No. The framework is Claude Code or nothing.

### git

- **Vendor:** Apple (Xcode Command Line Tools on macOS) or your Linux distribution package
- **Purpose:** Cloning the framework repo and pulling updates.
- **Install command:** `xcode-select --install` (macOS) or `apt install git` / equivalent (Linux)
- **Verify command:** `git --version`
- **Network endpoints:** `github.com:443` (HTTPS clone only)
- **Optional:** No.

### Anthropic API key

- **Vendor:** Anthropic; provisioned through the operator's account or the engagement's billing
- **Purpose:** Authenticates Claude Code against the inference endpoint.
- **Install procedure:** Either run `claude` and follow the `/login` OAuth flow, or set `ANTHROPIC_API_KEY` as an environment variable before first invocation. The OAuth path ties usage to a personal Anthropic account; the env-var path is the standard choice when the engagement issues its own key.
- **Verify command:** `claude -p "Reply with the literal word OK and nothing else."` returns `OK`.
- **Network endpoints:** `api.anthropic.com:443`
- **Optional:** No.

### bash (or zsh)

- **Vendor:** Operating system default
- **Purpose:** Runs `bootstrap.sh`, every session-start hook, and the shell snippets embedded throughout the skills.
- **Install procedure:** Preinstalled on macOS and every common Linux distribution.
- **Verify command:** `bash --version`
- **Network endpoints:** None.
- **Optional:** No.

### Terminal

- **Vendor:** Apple (Terminal.app), or any approved alternative (iTerm2, Warp, Alacritty)
- **Purpose:** The interactive surface where `claude` runs.
- **Install procedure:** Terminal.app is preinstalled on macOS. Alternatives need to clear IT approval per `external-tool-approval.md` before use on a managed device.
- **Verify command:** Open the application and run `claude --version` inside it.
- **Network endpoints:** None for Terminal.app. Alternatives may phone home for update checks; verify per app.
- **Optional:** No (some terminal is required), but the specific application is operator choice.

### Tier 0 verification block

The `initial-install` skill runs this block first. If any line fails, the skill stops and surfaces the install instructions for that one tool only.

```bash
which claude && claude --version
git --version
bash --version
claude -p "Reply with the literal word OK and nothing else."
```

All four passing means Tier 0 is met and the skill proceeds to Tier 1.

### Tier 0 network endpoints (for IT submission)

| Endpoint | Tool | Direction | Why |
|---|---|---|---|
| `api.anthropic.com:443` | Claude Code | Outbound HTTPS | Prompt routing, model inference |
| `github.com:443` | git | Outbound HTTPS | Clone the public framework repo |

These two endpoints alone cover the minimum-viable framework. Everything below is additive.

---

## Tier 1: Recommended for parity

Seven tools. The framework remains functional without them, but several skills degrade or fail entirely, and the operator gives up retrieval and editing capabilities that the rest of the system assumes. The `initial-install` skill walks each as a "install now?" prompt that defaults to yes.

### Homebrew

- **Vendor:** Homebrew.org (open source)
- **Purpose:** macOS package manager. The install path for most of the CLI utilities below.
- **Install command:** `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`
- **Verify command:** `brew --version`
- **Network endpoints:** `raw.githubusercontent.com:443`, `formulae.brew.sh:443`, `ghcr.io:443`
- **Optional:** Effectively no on macOS. Linux operators substitute their distribution package manager and skip Homebrew entirely.
- **What you lose if you skip:** Manual install paths for every CLI tool below. Doable but slow.

### ripgrep

- **Vendor:** BurntSushi (open source); install via Homebrew
- **Purpose:** Pattern search across the working folder. The `sanitization-scan` skill and the change-protocol sweep both shell out to `rg`.
- **Install command:** `brew install ripgrep`
- **Verify command:** `rg --version`
- **Network endpoints:** None at runtime.
- **Optional:** No if you plan to run sanitization scans or the change-protocol sweep.
- **What you lose if you skip:** `sanitization-scan` fails. Claude Code's bundled Grep tool keeps working for in-session searches, but the bash-level `rg` calls in skills break.

### jq

- **Vendor:** stedolan / jqlang (open source); install via Homebrew
- **Purpose:** JSON parsing in shell scripts. Used by `bootstrap.sh` fallback paths and by skills that patch MCP configuration files.
- **Install command:** `brew install jq`
- **Verify command:** `jq --version`
- **Network endpoints:** None.
- **Optional:** Soft no. A bash fallback exists in `bootstrap.sh`, but several skills assume `jq` is present.
- **What you lose if you skip:** Slower fallback paths in a few skills; some configuration-patching workflows become manual.

### Node.js 18+

- **Vendor:** Node.js Foundation; install via Homebrew or vendor package
- **Purpose:** Required by any npm-distributed MCP server, including the Smart Connections MCP that backs semantic search.
- **Install command:** `brew install node`
- **Verify command:** `node --version`
- **Network endpoints:** `registry.npmjs.org:443` during install.
- **Optional:** Skip only if you do not plan to run semantic search and have no other npm-distributed MCP in scope.
- **What you lose if you skip:** Semantic search over the working folder (the Smart Connections MCP path), and any future MCP that arrives via npm.

### Obsidian

- **Vendor:** Obsidian.md
- **Purpose:** Visual markdown editor for the working folder. The Smart Connections plugin runs inside Obsidian and is the only on-device path for vault embedding.
- **Install procedure:** Download the `.dmg` (or platform equivalent) from `obsidian.md` and install.
- **Verify procedure:** Open Obsidian and confirm the working folder loads as a vault.
- **Network endpoints:** `obsidian.md:443` for license check on launch; the core editor itself is offline.
- **Optional:** Yes for operators who prefer another editor and skip semantic search. Required if you want the Smart Connections embedding path.
- **What you lose if you skip:** No semantic search. You can still read and edit markdown in any editor; you just give up meaning-based retrieval.
- **IT approval:** Requires approval per `external-tool-approval.md` on managed devices.

### Smart Connections (Obsidian plugin)

- **Vendor:** Brian Petro (community plugin)
- **Purpose:** On-device embedding of the working folder. Generates the `.smart-env/` index that the Smart Connections MCP reads.
- **Install procedure:** In Obsidian, open Settings, go to Community plugins, browse for "Smart Connections," install, and enable.
- **Verify procedure:** Open the Smart Connections sidebar inside Obsidian and confirm initial embedding completes.
- **Network endpoints:** None. Embedding happens locally.
- **Optional:** Required if you want semantic search.
- **What you lose if you skip:** No embeddings; the Smart Connections MCP has nothing to query.
- **IT approval:** Plugin vetting per `external-tool-approval.md`.

### smart-connections MCP server

- **Vendor:** `gogogadgetbytes/smart-connections-mcp` on GitHub (community)
- **Purpose:** Exposes the on-device embeddings to Claude Code so the operator can ask meaning-based questions of the working folder.
- **Install procedure:** Follow the build and registration steps in `activate-semantic-search.md`. Clone the repo, run `npm install` and `npm run build`, then register the server in Claude Code's config with `VAULT_PATH` set to the working folder.
- **Verify procedure:** `node <path>/smart-connections-mcp/dist/index.js` boots without error; from inside Claude Code, `search_by_text` returns results against the indexed folder.
- **Network endpoints:** None at runtime; the server reads the local `.smart-env/` index.
- **Optional:** Required for the semantic-search workflow.
- **What you lose if you skip:** Cross-folder retrieval, meaning-based search, and the `search_by_text` / `search_similar` / `get_note` / `get_model_info` / `list_indexed` MCP tools.
- **IT approval:** Local-only MCP server. Submit per `external-tool-approval.md` Category 1; the local-only profile is low-risk because there are no outbound network calls.

### Tier 1 network endpoints

| Endpoint | Tool | Direction | Why |
|---|---|---|---|
| `raw.githubusercontent.com:443` | Homebrew install | Outbound HTTPS | Bootstrap script source |
| `formulae.brew.sh:443` | Homebrew | Outbound HTTPS | Formula metadata |
| `ghcr.io:443` | Homebrew | Outbound HTTPS | Bottle (binary) downloads |
| `registry.npmjs.org:443` | npm | Outbound HTTPS | Node package downloads |
| `obsidian.md:443` | Obsidian | Outbound HTTPS | App and plugin browser |
| `github.com:443` | git clone of `smart-connections-mcp` | Outbound HTTPS | MCP server source |

### Tier 1 install order

Dependencies dictate the order. The `initial-install` skill walks them this way:

1. Xcode Command Line Tools (macOS only, dependency for Homebrew)
2. Homebrew
3. ripgrep, jq, Node.js (Homebrew formulae, fast)
4. Obsidian (desktop app, around five minutes)
5. Smart Connections plugin (in-app, around fifteen to thirty minutes for initial embedding on a populated folder; under a minute on a fresh install)
6. Smart Connections MCP server (git clone plus npm build, around five minutes)

---

## Tier 2: Optional / per-engagement

Nine tools. None are load-bearing. Each one adds a specific workflow or quality-of-life improvement. The `initial-install` skill surfaces these as a per-category menu after Tier 1 is in place.

### Cloud sync (engagement-dependent)

- **Tool:** Drive for Desktop (Google)
- **Purpose:** Sync the working folder across machines; one possible source for meeting-transcript ingest if the engagement stores transcripts in Drive.
- **Install procedure:** Download from `google.com/drive/download`.
- **Verify procedure:** Drive appears in the menu bar and the configured folder syncs.
- **Network endpoints:** `drive.google.com:443`, `apis.google.com:443`
- **Notes:** Requires a Google account. Many enterprise engagements block personal Google sync on managed devices. Submit per `external-tool-approval.md` and expect a conversation about data residency. Alternatives include Box, OneDrive, and SharePoint via the matching MCP, each behind its own approval gate.

### GitHub CLI

- **Tool:** `gh`
- **Purpose:** Repository creation and pull-request management from the terminal.
- **Install command:** `brew install gh`
- **Verify command:** `gh --version`
- **Network endpoints:** `api.github.com:443` (only when authenticated)
- **Notes:** Not framework-required. Useful for operators who want to manage repos without leaving the shell.

### iTerm2

- **Tool:** iTerm2
- **Purpose:** Alternative terminal with split panes, profiles, and a hotkey window.
- **Install procedure:** Download from `iterm2.com`.
- **Verify procedure:** Launch the application.
- **Network endpoints:** `iterm2.com:443` for update checks.
- **Notes:** Pure operator preference. Terminal.app handles everything the framework does. Submit per `external-tool-approval.md` if the device is managed.

### tmux

- **Tool:** tmux
- **Purpose:** Long-running sessions, multi-pane terminal layouts, pair-coding workflows.
- **Install command:** `brew install tmux`
- **Verify command:** `tmux -V`
- **Network endpoints:** None.
- **Notes:** Operator preference. Worth installing if you regularly run Claude Code sessions that span hours.

### direnv

- **Tool:** direnv
- **Purpose:** Auto-load per-folder environment variables. Handy when the operator works across multiple engagements on one machine and each needs its own configuration.
- **Install procedure:** `brew install direnv`, then add `eval "$(direnv hook zsh)"` (or the bash equivalent) to your shell rc file.
- **Verify command:** `direnv version`
- **Network endpoints:** None.
- **Notes:** Operator preference. Recommended for multi-engagement machines.

### fzf

- **Tool:** fzf
- **Purpose:** Fuzzy file and history finder. A few skills use it for interactive selection when present.
- **Install procedure:** `brew install fzf && $(brew --prefix)/opt/fzf/install`
- **Verify command:** `fzf --version`
- **Network endpoints:** None.
- **Notes:** Quality-of-life only.

### yt-dlp

- **Tool:** yt-dlp
- **Purpose:** Video download for any operator-built video-transcript pipeline.
- **Install command:** `brew install yt-dlp`
- **Verify command:** `yt-dlp --version`
- **Network endpoints:** Per video host.
- **Notes:** No framework skill ships using this today. Install only if you are building a custom video workflow.

### ffmpeg

- **Tool:** ffmpeg
- **Purpose:** Frame extraction and audio processing for video-analysis workflows. Pairs with yt-dlp.
- **Install command:** `brew install ffmpeg`
- **Verify command:** `ffmpeg -version`
- **Network endpoints:** None.
- **Notes:** Install alongside yt-dlp if you need video processing.

### Xcode Command Line Tools

- **Tool:** Xcode Command Line Tools
- **Purpose:** Compilers, the `git` baseline on macOS, and build dependencies for any source-built tool or Node native module.
- **Install command:** `xcode-select --install`
- **Verify command:** `xcode-select -p`
- **Network endpoints:** `swdist.apple.com:443` once during install.
- **Notes:** macOS only. Usually already present on developer machines; a prerequisite for Homebrew and for installing `git` from scratch.

### Tier 2 network endpoints (only the ones not listed above)

| Endpoint | Tool | Why |
|---|---|---|
| `drive.google.com:443` | Drive for Desktop | Sync |
| `apis.google.com:443` | Drive for Desktop | OAuth and API |
| `api.github.com:443` | GitHub CLI | Authenticated API calls |
| `iterm2.com:443` | iTerm2 | Update checks |
| `swdist.apple.com:443` | Xcode CLT | One-time install |
| Per video host | yt-dlp | Per video |

---

## MCP catalog

Model Context Protocol servers the framework knows how to wire up. Each ships **disabled**. Activation requires routing the candidate through `external-tool-approval.md` Category 1 (MCP servers) first, recording the decision in `Universal/RECORD-decisions/_index.md`, and registering the result in `Universal/READ-references-and-knowledge/approved-tools.md`.

The `initial-install` skill never activates an MCP automatically. It surfaces the candidate list, marks which are already approved (by checking `approved-tools.md`), and routes the rest through the approval flow before configuration.

### Local-only MCP

#### smart-connections

- **Vendor:** `gogogadgetbytes/smart-connections-mcp` on GitHub
- **Purpose:** Semantic search over the working folder.
- **Distribution:** git clone plus `npm install` plus `npm run build`. Full procedure in `activate-semantic-search.md`.
- **Local-or-cloud:** Local. Reads the on-device `.smart-env/` index Obsidian's Smart Connections plugin produces. No outbound calls.
- **Integration notes:** Register in Claude Code's MCP configuration as a stdio server with `VAULT_PATH` pointing at the working folder. Exposes `search_by_text`, `search_similar`, `get_note`, `get_model_info`, `list_indexed`.
- **IT-approval considerations:** Low risk. Local-only, no network egress, no third-party data sharing. Often approved on a fast track.

### Cloud-backed MCPs

Each requires per-scope review during approval. The operator submits with the specific scope set the engagement needs, not the maximum set.

#### Figma

- **Vendor:** Figma (official)
- **Purpose:** Read design context, components, and variables from Figma files.
- **Distribution:** npm package or vendor binary.
- **Local-or-cloud:** Cloud (Figma API).
- **Typical OAuth scopes:** `file_read`
- **Token storage:** OS keychain.
- **Integration notes:** Useful on any engagement that touches UI work. The framework's design skills (extraction, accessibility review, handoff) compose well with it.
- **IT-approval considerations:** Standard cloud-MCP review. Confirm the file-read scope is sufficient and that no write-back is in scope.

#### Google Drive

- **Vendor:** Anthropic-blessed or community Drive MCP
- **Purpose:** File storage; one possible source for transcript ingest.
- **Distribution:** npm package or vendor binary.
- **Local-or-cloud:** Cloud (Google API).
- **Typical OAuth scopes:** `drive.readonly` at minimum; expand only if the engagement needs write-back.
- **Token storage:** OS keychain.
- **Integration notes:** Required when Drive is the engagement's storage of record and the operator wants Claude Code to read files directly. The `process-meeting-transcripts` skill treats Drive as one of several possible transcript sources.
- **IT-approval considerations:** Personal Google accounts are usually blocked on enterprise devices. Use the engagement's Google Workspace tenant if Drive is in scope; otherwise route to Box, OneDrive, or SharePoint instead.

#### Gmail

- **Vendor:** Anthropic-blessed or community Gmail MCP
- **Purpose:** Inbox triage, search, and drafting.
- **Distribution:** npm package or vendor binary.
- **Local-or-cloud:** Cloud (Gmail API).
- **Typical OAuth scopes:** `gmail.readonly` at minimum; `gmail.send` only if drafting is in scope.
- **Token storage:** OS keychain.
- **Integration notes:** Useful only when Gmail is the engagement's email of record. Many engagements use Microsoft 365; route to an MS365 MCP in those cases.
- **IT-approval considerations:** Inbox access is a high-trust scope. Expect detailed review of which mailboxes and which scopes.

#### Google Calendar

- **Vendor:** Anthropic-blessed or community Calendar MCP
- **Purpose:** Scheduling, availability, and daily briefing workflows.
- **Distribution:** npm package or vendor binary.
- **Local-or-cloud:** Cloud (Calendar API).
- **Typical OAuth scopes:** `calendar.readonly`
- **Token storage:** OS keychain.
- **Integration notes:** Read-only is typically sufficient; reach for write scopes only if the workflow drafts events.
- **IT-approval considerations:** Same caveats as Gmail. Use the engagement's tenant if calendar is in scope.

#### Linear

- **Vendor:** Linear (official)
- **Purpose:** Tickets, projects, and roadmap views.
- **Distribution:** npm package or vendor binary.
- **Local-or-cloud:** Cloud (Linear API).
- **Typical OAuth scopes:** Per Linear's scope catalog.
- **Token storage:** OS keychain.
- **Integration notes:** Most useful for product and engineering engagements that run Linear as their tracker. Composes with the framework's product-management skills.
- **IT-approval considerations:** Standard cloud-MCP review.

#### Atlassian (Jira and Confluence)

- **Vendor:** Atlassian (official)
- **Purpose:** Tickets in Jira and pages in Confluence.
- **Distribution:** npm package or vendor binary.
- **Local-or-cloud:** Cloud (Atlassian API).
- **Typical OAuth scopes:** Per Atlassian's scope catalog.
- **Token storage:** OS keychain.
- **Integration notes:** Common at enterprise engagements. The MCP exposes both Jira and Confluence under one connector.
- **IT-approval considerations:** Standard cloud-MCP review. Confirm the scope split between Jira and Confluence matches what the engagement needs.

#### Slack

- **Vendor:** Slack (official)
- **Purpose:** Message history, channel context, decision archaeology.
- **Distribution:** npm package or vendor binary.
- **Local-or-cloud:** Cloud (Slack API).
- **Typical OAuth scopes:** Per Slack's scope catalog.
- **Token storage:** OS keychain.
- **Integration notes:** Useful when the engagement provisions a workspace and runs decisions through Slack. Read scopes are usually sufficient.
- **IT-approval considerations:** Workspace-admin approval is the gating step. Many workspaces require app-installation by an admin before the MCP can authenticate.

#### Box

- **Vendor:** Box (official) or community
- **Purpose:** File storage where the engagement standardizes on Box.
- **Distribution:** npm package or vendor binary.
- **Local-or-cloud:** Cloud (Box API).
- **Typical OAuth scopes:** Per Box's scope catalog.
- **Token storage:** OS keychain.
- **Integration notes:** Substitute for Google Drive on Box-standardized engagements.
- **IT-approval considerations:** Standard cloud-MCP review.

#### SharePoint / Microsoft 365

- **Vendor:** Microsoft (official) or community
- **Purpose:** Enterprise file storage, calendar, mail, and Teams meeting transcripts.
- **Distribution:** npm package or vendor binary.
- **Local-or-cloud:** Cloud (Microsoft Graph API).
- **Typical OAuth scopes:** Per Microsoft Graph's scope catalog.
- **Token storage:** OS keychain.
- **Integration notes:** The natural choice for MS365-standardized engagements. One MCP can cover OneDrive, SharePoint, Outlook, and Teams depending on scope.
- **IT-approval considerations:** Tenant-admin consent is often the gating step. Expect a longer approval cycle than single-app MCPs.

### MCP activation procedure

The procedure is the same for every MCP. Follow it once per server.

1. Operator drafts the `external-tool-approval.md` submission for the MCP.
2. Client IT approves (or rejects with conditions).
3. Operator records the decision in `Universal/RECORD-decisions/_index.md`.
4. Operator adds the MCP entry to Claude Code's MCP configuration.
5. Operator restarts Claude Code so the new server is registered.
6. Operator runs the MCP-specific verification probe.
7. Operator adds the row to `Universal/READ-references-and-knowledge/approved-tools.md`.

The `initial-install` skill checks `approved-tools.md` before suggesting any MCP and surfaces only the ones that are already cleared or are explicitly part of the engagement's planned stack.

---

## Filesystem capabilities

Claude Code can read, write, edit, glob, grep, and run shell commands inside the working folder. The exact shape of what is allowed depends on the host environment:

- On a local install, Claude Code runs as the operator's user and inherits normal filesystem permissions. `rm` is technically available.
- The framework convention is still to quarantine candidates by moving them into `_trash/YYYY-MM-DD/<original/path>/` and letting the operator empty the trash through their file manager. Rationale: an accidental `rm -rf` in an AI session can be costly, and a human-in-the-loop empty step is cheap insurance.

Full deletion-discipline rules live in `Universal/READ-references-and-knowledge/concepts/file-deletion-constraint.md`.

---

## Approved-tools registry

Once a tool clears `external-tool-approval.md`, record it in `Universal/READ-references-and-knowledge/approved-tools.md`. That file is the single source of truth for what is allowed on the operator's current device. The `initial-install` skill reads it to know which MCPs to skip the approval flow for, and which to route through the approval procedure.

The registry is per-device and per-engagement. When the operator changes machines or starts a new engagement, the registry resets.

---

## Cross-references

- Approval procedure for any external tool or MCP: `Universal/FOLLOW-workflows-and-guides/playbooks/external-tool-approval.md`
- End-to-end portable framework architecture: `Universal/FOLLOW-workflows-and-guides/playbooks/portable-ai-ecosystem.md`
- Semantic-search activation runbook: `Universal/FOLLOW-workflows-and-guides/playbooks/activate-semantic-search.md`
- Fresh-machine setup walkthrough: `Universal/FOLLOW-workflows-and-guides/playbooks/new-machine-setup.md`
- File-deletion convention: `Universal/READ-references-and-knowledge/concepts/file-deletion-constraint.md`
- Approved-tools registry: `Universal/READ-references-and-knowledge/approved-tools.md`
- Foundational decisions log: `Universal/RECORD-decisions/_index.md`

---

*History: [Universal/RECORD-decisions/_index.md](RECORD-decisions/_index.md)*
