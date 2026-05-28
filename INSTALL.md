# INSTALL.md

Step-by-step install for the portable-ai-ecosystem repo on a new device. Follow top-to-bottom. Run-time on a cooperative device: roughly 20 to 40 minutes, most of which is waiting for IT approval if you're on a managed laptop.

**Voice loaded:** do-not + personal + formats:doc:detailed.

---

## 1. What you'll have at the end

A working folder on your device containing the markdown vault, voice guides, soft-partition initiative scaffolding, and a small set of runnable Claude Code skills. Opening a terminal in that folder and running `claude` loads the ecosystem into context: the session-start hook fires, the four-step voice composition rule loads, and the `validate-install` skill is invokable to verify the install. Updates flow one-way from GitHub via `git pull`; your in-progress initiative work stays local and never travels back to the public repo.

### 5-item validation checklist

1. `claude` launches in the working folder and the session-start hook fires (loads `Universal/AGENTS.md` into context).
2. Asking "what is the 4-step voice composition rule?" returns the rule verbatim from the voice files.
3. The `validate-install` skill runs the 6-probe check and prints a green health card.
4. `git pull` from the working folder fast-forwards without prompts (and without write capability against the remote).
5. A short written output ends with a `Voice loaded: ...` self-attestation line.

If all five are green, the install is live. If any are red, jump to §8 troubleshooting.

---

## 2. Prerequisites

Required:

- **Claude Code** installed and authenticated. `which claude` returns a path; `claude --version` returns a version string; the first `claude` invocation completed an OAuth flow against your Anthropic account.
- **git** installed. `git --version` returns 2.x or newer.
- **Terminal access.** Terminal.app on macOS or any standard terminal emulator. iTerm2 is fine.
- **Write permission to a working folder.** You'll clone the repo into this folder. Pick a location that's easy to wipe and re-clone if you want a fresh start; `~/ai-workspace/` is a reasonable default, sibling to `~/Documents/`.

Optional, only needed if you plan to run the sanitization-scan skill later:

- **ripgrep** (`rg`). Claude Code bundles ripgrep in recent versions, so a system install is usually not needed.
- **jq**. Used for parsing JSON. The bootstrap script has a pure-bash fallback if jq is absent.

Not required: admin rights, Homebrew, Docker, Node.js system-wide, SSH key generation, GitHub authentication, any MCP server, Cowork, Claude Desktop.

---

## 3. For users on a managed device

If your laptop is managed by IT or InfoSec, submit the approval ask below before starting §4. Copy-paste, fill in your details, file the ticket.

### Approval request template

> **Subject:** Approval request for Claude Code + public GitHub clone for AI workflow tooling
>
> **Requestor:** [your name]
>
> **Summary:** I want to install Anthropic's Claude Code CLI on my [company] laptop and clone one public GitHub repo (read-only, anonymous HTTPS) into a working folder under my home directory. The repo contains markdown configuration files and shell skill definitions. There are no executables and no auto-run code beyond an opt-in bootstrap script that I run manually once.
>
> **Items requested:**
>
> | # | Item | Vendor / Source | Purpose | Network / Data |
> |---|------|-----------------|---------|----------------|
> | 1 | Claude Code CLI | Anthropic | Primary AI interface | Outbound HTTPS to `api.anthropic.com`. Prompts plus the file contents I explicitly read go to Anthropic under standard enterprise data-handling terms. |
> | 2 | Anthropic account auth | Existing Anthropic account or company-issued seat | Authenticates Claude Code | OAuth flow opens browser; token stored in OS keychain. |
> | 3 | git CLI | Apple Xcode Command Line Tools (already present on most managed Macs) or equivalent on other OSes | Clone the repo and pull updates | Outbound HTTPS to `github.com`. Standard git operations only. |
> | 4 | GitHub.com network access | GitHub Inc. (`github.com`, `api.github.com`) | Read-only HTTPS clone of one public repo | Outbound HTTPS (443). No code or data is pushed back; the repo is public and the clone is anonymous. |
> | 5 | Terminal access | Built-in Terminal.app or equivalent | Where `claude` runs | None beyond standard shell operation. |
> | 6 | Write access to a working folder | Filesystem permission, no admin needed | Vault clone target. I'll pick a path like `~/ai-workspace/` | Local filesystem only. |
>
> **Data flow:** Claude Code talks to `api.anthropic.com`. Git talks to `github.com` only, read-only, anonymous HTTPS against a public repository. Nothing on the device is uploaded by either tool without my explicit prompt.
>
> **What I'm NOT requesting:** No admin privileges. No Homebrew install (using built-in tools or company-approved binaries). No Docker. No SSH key generation (the repo is public, anonymous HTTPS clone works). No GitHub credentials or PAT. No MDM exceptions. No EDR allowlist changes beyond standard `github.com` and `api.anthropic.com`. No local MCP servers. No scheduled tasks or background daemons.
>
> **Why this matters:** The repo contains voice guides, soft-partition rules, and a small set of automated checks that meaningfully improve my Claude productivity. Without it I lose roughly 30 to 40 percent of the value.

File the ticket, wait for explicit approval on each row, then proceed to §4.

---

## 4. Install steps

Each step has the action, the command to run, what success looks like, and where to go if it fails. Run them in order.

### Step 1. Verify Claude Code is installed and authenticated

```bash
which claude
claude --version
```

**Expected output:** A path (typically `/usr/local/bin/claude` or `~/.local/bin/claude` or similar) and a version string like `claude 1.x.x`.

If `claude --version` works but you haven't authenticated yet:

```bash
claude
# In the interactive prompt:
/login
# Follow the OAuth flow in your browser. The token is stored in your OS keychain.
```

**Verify auth:**

```bash
claude -p "Reply with the literal word OK and nothing else."
# Should print: OK
```

**If `claude: command not found`:** Claude Code isn't installed or isn't on your PATH. Install per Anthropic's documentation, then re-source your shell config or restart the terminal.

### Step 2. Verify git is installed

```bash
git --version
```

**Expected output:** `git version 2.x.x` (any 2.x is fine).

**If `git: command not found`** on macOS: run `xcode-select --install`. On Linux: use your package manager (`apt install git`, `dnf install git`). If installation requires admin and you don't have it, file an IT ticket.

### Step 3. Clone the repo over anonymous HTTPS

The repo is public and MIT-licensed. No GitHub account, no SSH key, no PAT needed for cloning.

```bash
cd ~
git clone https://github.com/cntrout/portable-ai-ecosystem.git ai-workspace
cd ai-workspace
```

The folder name (`ai-workspace`) is your choice. Pick whatever convention you prefer; `~/ai-workspace/` is a sibling of `~/Documents/`, easy to wipe.

**Expected output:**

```
Cloning into 'ai-workspace'...
remote: Enumerating objects: ...
Receiving objects: 100%
Resolving deltas: 100%
```

**Verify:**

```bash
ls -la
# Should include: AGENTS.md, CLAUDE.md, .claude/, Universal/, Initiatives/
```

**If the clone hangs or times out:** outbound HTTPS to github.com is blocked. Escalate to IT.

### Step 4. Run the bootstrap script

The script lives at `Universal/RUN-automations/scripts/bootstrap.sh` and handles the device-specific configuration that can't be checked into source control: creating local-state directories, copying `settings.json.template` to `settings.local.json`, making the session-start hook executable, writing the one-way-flow `.gitignore` for `Initiatives/`, setting `pull.ff = only` on the local git config, and writing a completion marker.

The script is idempotent, so re-running it is always safe.

**If you want to see what the script will do before running it:**

```bash
./Universal/RUN-automations/scripts/bootstrap.sh --dry-run
```

This prints every change without making any.

**Run the bootstrap:**

```bash
./Universal/RUN-automations/scripts/bootstrap.sh
```

**Expected output:** A series of `[bootstrap]` log lines ending with:

```
===============================================================================
bootstrap complete.

Next steps:
  1. Run `claude` in this directory. The session-start hook should fire and
     load Universal/AGENTS.md into context.
  2. Invoke the validate-install skill to run the 6-probe check.
  3. Once validation passes, invoke engagement-bootstrap-from-urls to seed
     the engagement layer from the client's public URLs.
...
===============================================================================
```

**If the script fails with `error: $REPO_ROOT/AGENTS.md not found`:** you're not running from a properly-cloned repo. Re-check Step 3 succeeded and that `pwd` is at the repo root.

**If the script fails with `Permission denied`:** the script isn't executable. Run `chmod +x Universal/RUN-automations/scripts/bootstrap.sh` first.

### Step 5. Verify the bootstrap completion marker

```bash
cat .claude/_bootstrap-state/bootstrap-completed.txt
```

**Expected output:** A line like:

```
2026-05-27T14:32:11 bootstrap.sh completed successfully
```

If you re-run bootstrap later, you'll see additional timestamped lines below the first.

### Step 6. Configure Claude Code settings

The bootstrap script already copied `.claude/settings.json.template` to `.claude/settings.local.json`. Verify it's there:

```bash
cat .claude/settings.local.json
```

**Expected output:** A JSON object with a `permissions.allow` array including at minimum `Read`, `Write`, `Edit`, `Grep`, `Glob`, `Bash`, `WebFetch`, and `WebSearch`.

`settings.local.json` is in `.gitignore`. Anything you edit here stays on your device; it never flows back to the public repo. The template is the canonical source for the default permission set; edit `settings.local.json` if you want narrower or wider permissions on this specific device.

### Step 7. Open Claude Code in the working folder

```bash
claude
```

**Expected:** Claude Code starts in the current directory. The session-start hook at `.claude/hooks/session-start.sh` runs automatically and injects `Universal/AGENTS.md` into the conversation context.

Ask Claude:

```
> What context did you load? List the files by absolute path.
```

The reply should mention both `~/ai-workspace/CLAUDE.md` (loaded by the native cascade) and `~/ai-workspace/Universal/AGENTS.md` (injected by the session-start hook).

If only the first is mentioned, the hook isn't firing. Check `cat .claude/settings.json` and confirm there's a `SessionStart` entry pointing at `.claude/hooks/session-start.sh`. Re-run bootstrap if the entry is missing.

### Step 8. Invoke the validate-install skill

In the same `claude` session:

```
> /validate-install
```

**Expected:** The skill walks through six probes, prints a green health card, and writes a dated install-record to `Universal/RECORD-decisions/`. If anything is red or amber, the skill prints a remediation pointer for that specific probe.

### Step 9. Run the initial-install orchestrator (recommended)

After validation passes, the easiest path through the rest of the install is the `initial-install` orchestrator skill. It walks you through seven more phases (tool installation, optional MCP activation, hooks and scheduled tasks, per-device config, voice customization, optional engagement bootstrap, final validation) and persists progress to `.claude/_install-state/state.json` so you can pause and resume across sessions.

In the same `claude` session:

```
> /initial-install
```

**Expected:** The orchestrator runs a 12-check pre-flight matrix (terminal, shell, OS, locale, disk space, working-folder write, network reachability for `github.com` and `api.anthropic.com`, MDM indicators, time drift, bash version), surfaces any warnings, and prompts you to confirm before advancing. It then walks state by state, delegating to:

- `initial-setup` (S8 per-device config: friction-ledger path, cadence, voice plan, health-check posture)
- `operator-voice-bootstrap` (S9 voice customization, path C only)
- `wire-hooks-and-tasks` (S7 hooks + scheduled tasks)
- `engagement-bootstrap-from-urls` (S10 engagement layer)
- `validate-install` (S3 entry and S11 final validation)

You can pause after any phase and re-invoke `/initial-install` to resume. Total optimistic run-time: roughly 60 minutes. Realistic on a managed device: 3-4 hours spread across days, with IT-approval gates between phases.

**Manual path.** If you prefer to skip the orchestrator and run the sub-skills directly:

```
> /initial-setup
```

`initial-setup` walks through:
1. Framework root confirmation (auto-detected via git)
2. Friction-ledger path (default `Universal/PRODUCE-outputs/friction-ledger.md`)
3. Friction-ledger-capture cadence and time of day (default daily evening)
4. Self-improvement-review cadence and time of day (default weekly Friday morning)
5. Voice customization plan (use shipped author voice / customize now / customize later)
6. Workspace-health-check posture (v1.3 placeholder)

Writes the config to `.claude/_setup-state/config.json` and appends a row to `Universal/RECORD-decisions/_index.md`. Idempotent; safe to re-invoke any time to revisit settings.

After `initial-setup`, invoke `/wire-hooks-and-tasks` to load the launchd plists, `/operator-voice-bootstrap` if you chose path C, and `/engagement-bootstrap-from-urls` if you want the engagement layer populated. Re-run `/validate-install` at the end for the final check.

The next section is the spec for what the validate-install skill checks, in case you prefer to run the probes manually.

---

## 5. Validation

These six probes are the canonical "is it working?" battery. The `validate-install` skill runs them for you and writes an install-record. If you want to run them manually instead, the prompts and expected response shapes are below.

| # | Prompt | Expected response shape |
|---|--------|--------------------------|
| 1 | "What's the 4-step voice composition rule?" | Claude recalls the four steps from `voice-composition.md`: do-not + personal + formats + project voice. |
| 2 | "List the active initiatives." | Claude enumerates `Initiatives/*/` directories with their `README.md` one-liners. On a fresh install this is empty or near-empty; that's fine. |
| 3 | "What's the folder-creation rule when I want a new subfolder?" | Claude cites the three rules from `folder-creation-rules.md`: README/_index in the same change, no folders at vault root or section root, full rules link. |
| 4 | "Try to push to the remote." | Claude reports there's no push credential on the device, so push is impossible. The failure message names the missing credential. This is by design; the repo flow is one-way. |
| 5 | "When I run `git pull`, what gets updated and what stays untouched?" | Claude explains the `Initiatives/.gitignore` layer. Framework updates flow; in-progress work in `Initiatives/` stays untouched. |
| 6 | (inside an initiative folder) "I'm about to draft a customer-facing one-pager. Self-attest the voice layers you've loaded." | Claude reports Layer 1 (do-not) + Layer 2 (personal + formats:doc) + Layer 3 (voice.md) loaded, per the four-step rule. |

All six green = ecosystem is live. Any red = jump to §8 troubleshooting.

---

## 6. Day-1 next step

You have a working ecosystem with no engagement-specific context yet. Voice Layer 3 is empty, the glossary is empty, brand notes are empty.

Seed the engagement layer from a small set of public URLs (your company's website, blog, public docs, a few public talks if you have them):

```
> /engagement-bootstrap-from-urls
```

The skill walks you through providing the URLs, then reads them, extracts brand voice signals, populates the engagement-layer voice file at `Universal/FOLLOW-workflows-and-guides/voice/voice.md`, builds an initial glossary, and writes a thesis stub.

Run-time: roughly 5 to 15 minutes depending on how many URLs you provide.

After it finishes, re-invoke `/validate-install` to confirm the new layer is loading correctly.

---

## 7. Day-2 operations

### Pulling updates

```bash
cd ~/ai-workspace
git fetch
git status   # confirm "Your branch is behind ... by N commits, and can be fast-forwarded."
git pull
```

`Initiatives/.gitignore` was written by bootstrap; it preserves your in-progress work. The `pull.ff = only` config from bootstrap means pulls either fast-forward cleanly or fail loudly (no surprise merge commits).

If `.claude/` or `Universal/RUN-automations/scripts/` changed in the pulled update, re-run bootstrap to pick up any new local-state setup:

```bash
./Universal/RUN-automations/scripts/bootstrap.sh   # idempotent
claude                    # restart your Claude Code session
/validate-install         # re-verify
```

### Customizing the framework safely

Per `CONTRIBUTING.md`, the right way to adapt this framework is to fork it. If you've made local edits to playbooks, voice files, or other tracked files INSIDE your clone (rather than in your fork), `git pull` will produce merge conflicts. Three options:

1. **Use a fork**: clone your fork instead of the canonical repo. Pull upstream into a separate branch. Standard fork workflow.
2. **Stash before pulling**: `git stash && git pull && git stash pop`. Re-apply local edits and handle conflicts manually.
3. **Rebase your edits**: `git pull --rebase` if you've committed local changes. Resolve conflicts as they come.

The framework provides no automatic protection for tracked-file customizations. Initiative content under `Initiatives/` is gitignored and stays local; everything else is shared with upstream.

### Creating a new initiative

From inside Claude Code:

```
> /initiative-kickoff
```

The skill walks you through naming the initiative, scoping it, and authoring the folder under `Initiatives/{slug}/`. Initiative folders are gitignored by default, so your work there stays local. If you later want to graduate an artifact to the public layer, copy it to `Universal/` and commit through a separate flow (the repo is read-only against your origin, so authoring back to GitHub happens outside this device's scope).

### Lifecycle: Active to Archived

Initiatives follow a simple lifecycle: **Active** (current work) and **Archived** (closed out, kept for reference).

To archive:

```bash
cd ~/ai-workspace/Initiatives
mv {active-slug} _archive/{active-slug}
```

The `_archive/` subfolder is also gitignored. Archived initiatives stay searchable but drop out of the active-initiative list that `/validate-install` probe 2 enumerates.

### Pruning old initiatives

When an archived initiative is no longer worth keeping (typically after a year), delete the folder. Because everything in `Initiatives/` is gitignored, deletion is local-only and doesn't touch the repo.

---

## 8. Troubleshooting

| Failure | Fix |
|---------|-----|
| `claude: command not found` | PATH doesn't include Claude Code's bin directory. Re-source your shell config (`source ~/.zshrc` or equivalent), restart Terminal, or reinstall Claude Code. |
| `git clone` hangs and times out | Outbound HTTPS to github.com is blocked. Escalate to IT with the destination domain. |
| `./Universal/RUN-automations/scripts/bootstrap.sh: Permission denied` | Script isn't executable. Run `chmod +x Universal/RUN-automations/scripts/bootstrap.sh` and retry. |
| Bootstrap fails with `AGENTS.md not found` | Not running from the repo root. `cd` into the cloned folder first and re-run. |
| Session-start hook isn't firing (Claude doesn't see `Universal/AGENTS.md`) | Check `.claude/settings.json` has a SessionStart entry. Test the hook manually: `bash .claude/hooks/session-start.sh \| head`. If output is empty, `Universal/AGENTS.md` is missing from your clone; re-pull. |
| Voice rule recall fails (probe 1 of validation) | The voice-composition.md file isn't being read. Confirm `Universal/FOLLOW-workflows-and-guides/playbooks/voice-composition.md` exists in your clone. Re-pull if missing. |
| Voice self-attest line missing on written outputs | Rule is loaded but not being followed. Restart `claude`. If persistent across sessions, invoke `/validate-install` to re-anchor; if still persistent, file an issue. |
| `/validate-install` skill not found | `.claude/skills/validate-install/SKILL.md` isn't in your clone, or Claude Code didn't pick up the skills directory. Confirm the file exists; restart `claude` to re-scan skills. |
| `git pull` says "Your branch and 'origin/main' have diverged" | You have local commits or merge artifacts on a read-only checkout. Recover with `git reset --hard origin/main` (this discards any local commits; in-progress work in `Initiatives/` is gitignored and untouched). |
| TLS / SSL certificate errors on `git clone` or `claude` | Enterprise MITM proxy is intercepting TLS. Get the cert bundle from IT; for git: `git config --global http.sslCAInfo /path/to/ca-bundle.pem`. For Claude Code: set the `NODE_EXTRA_CA_CERTS` environment variable to the bundle path. |
| Path with spaces in the working folder breaks the hook | Don't put the working folder under a path with spaces. Use a path like `~/ai-workspace/` instead. If a space is unavoidable, audit `.claude/hooks/session-start.sh` for unquoted variable expansions and quote them. |

If none of these match what you're seeing, capture the failing command, its full output, your Claude Code version (`claude --version`), and your OS version, then file an issue at `https://github.com/cntrout/portable-ai-ecosystem/issues`.

---

*INSTALL.md is the public-facing companion to the install runbook in the main playbook. The runbook covers the design rationale; this file covers the steps.*
