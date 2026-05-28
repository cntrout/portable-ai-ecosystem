---
type: playbook
last_reviewed: 2026-05-27
sync_trigger: 2026-05-27-portable-ai-ecosystem-decisions-and-voice-pass
depends-on:
  - playbook:engagement-bootstrap-from-urls
  - playbook:change-protocol
  - playbook:folder-creation-rules
---

# Portable AI Ecosystem Playbook

Canonical migration path for moving an AI ecosystem onto a locked-down client device that allows only Claude Code in a terminal. No managed AI session host, no desktop AI app, no admin privileges, no cloud-drive sync, no preinstalled MCPs, and an IT/InfoSec approval gate in front of every third-party tool.

Written to be generic across engagements with these constraints. The first-run worked example (with engagement-specific decisions and paths) is in the appendix at the bottom.

## TL;DR

A public GitHub repo on the operator's personal account hosts the **framework only**: verb buckets, voice templates (Layers 1 and 2 scrubbed), playbook patterns, skill scaffolding, change-protocol, folder-creation rules. Zero client content lives in the repo, ever. On the client device, Claude Code clones the repo anonymously over HTTPS and runs `engagement-bootstrap-from-urls.md` against the client's public URLs to populate brand assets, voice Layer 3, glossary, product knowledge, and a starter thesis. Anything created on the client device stays on the client device. Push is impossible because the device has no push credential.

The playbook is written so that the first run and every subsequent run with the same constraints is a copy-paste. Engagement-specific details from the first run live in the appendix.

## When to run this

- A new client device must host the AI ecosystem (managed laptop, no admin)
- The operator's usual managed-session host is unavailable; only Claude Code in a terminal is approved
- Client IP constraints prevent shipping any past-client content
- A fresh, generic install is required

## Outcome

After end-to-end execution:

- A public repo on the operator's personal GitHub, named `portable-ai-ecosystem`, contains the generic scrubbed framework. Zero client content, zero past-client references, MIT-licensed for public reuse
- The client device has Claude Code installed and authenticated against a client-issued Anthropic API key (already provisioned), the repo cloned over anonymous HTTPS, and the bootstrap script applied
- `engagement-bootstrap-from-urls.md` has been run against the client's public URLs, populating brand assets, voice Layer 3, glossary, and a starter thesis fresh on the client device
- AGENTS.md / CLAUDE.md, the 4-step voice composition rule, and the folder-creation rules all load correctly in Claude Code
- Soft-partition initiatives are working for the client's roadmap items
- Push to the personal GitHub repo is impossible because the client device has no GitHub push credential at all
- The migration is repeatable for the next engagement with no re-design

## Resolved decisions (2026-05-27)

Five decisions locked between the playbook draft and this revision. They simplify the architecture and downstream sections reflect them. The "Effect" column documents the first-run worked example (see appendix) where it makes the implication concrete.

| # | Decision | Effect |
|---|----------|--------|
| 1 | **Repo is public on the operator's personal GitHub**, named `portable-ai-ecosystem`. | Anonymous HTTPS clone works on the client device. No SSH key, no PAT, no deploy key needed for read access. Push is naturally impossible without a credential. |
| 2 | **MIT license** for public-share intent. | Anyone can fork, reuse, attribute. Aligns with the playbook's reuse-across-engagements purpose. |
| 3 | **Client-issued Anthropic API key** already provisioned on the client device. | The Anthropic data-flow question is closed: prompts route through the client's billing and contractual relationship with Anthropic, not the operator's personal account. (First-run worked example: client-issued key; see appendix.) |
| 4 | **Public site = public-AND-OK-to-ingest** under the client's policy. | The brand-and-voice extractor in `engagement-bootstrap-from-urls.md` can capture the client's public brand pages, including customer logos and named partnerships, without legal review. (First-run worked example: confirmed under the client's policy; see appendix.) |
| 5 | **Scrub-then-ship the operator's `personal.md` voice Layer 2.** | The voice baseline ships in the repo with all metadata about email extraction and time-period sourcing removed. The voice content itself stays intact. The operator's email-derived voice becomes the public framework's voice. |

## What ships in the repo, what doesn't

| Ships in the repo | Stays off the repo |
|---|---|
| Verb-bucket folder scaffold (READ-/FOLLOW-/PRODUCE-/RECORD-/RUN-) | Any client or past-client name |
| Root `AGENTS.md` / `CLAUDE.md` rule cascade, generic version, no client refs | `aboutme.md` (personal, family, non-compete details) |
| Voice Layer 1 (`do-not.md`) and Layer 2 (`personal.md` scrubbed, `formats.md`) | Past-client handoffs, exemplars named after past clients (e.g., engagement-specific invoice templates) |
| Voice Layer 3 as an **empty template** for the engagement bootstrapper to fill | `Universal/READ-references-and-knowledge/entities/{individual}.md` files |
| Playbooks (change-protocol, folder-creation-rules, voice-composition, this playbook, the engagement bootstrapper) | Decisions ledger content. A fresh empty ledger ships; the existing log stays personal |
| `engagement-bootstrap-from-urls.md`, the new generic engagement seeder | `.smart-env/`, `.health-check/`, `_trash/`, machine-generated outputs |
| Skill scaffolding (SKILL.md frontmatter convention, command file pattern) | Drive sync state, `.obsidian/` workspace state |
| README templates for every folder type | Anything matching the sanitization scan's flag set |
| `.gitignore`, bootstrap script, install runbook, `LICENSE` (MIT) | |

The repo is the *framework* of the AI workspace. Engagement content lives in the engagement, not the framework.

## Architecture changes (prior managed-session host → Claude Code, terminal-only)

| Surface | Prior (managed session host) | New (Claude Code) |
|---|---|---|
| Folder partition | Hard partition by client folder | Soft partition by initiative. Initiatives can see each other, but only one initiative's context loads at a time via `pwd` |
| Project structure | `Projects/{Client}/` with per-client verb-bucket mirror | One client per device. Top-level `Initiatives/{slug}/` for roadmap items. No `Projects/{Client}/` indirection |
| Voice Layer 3 | `Projects/{Client}/FOLLOW-workflows-and-guides/voice.md` | `Universal/FOLLOW-workflows-and-guides/voice/voice.md` (single client per device) |
| Clarifying questions | Dedicated structured-question tool | Conversational confirmation in chat |
| Scheduled tasks | Prior host's scheduler with auto-pickup | Manual prompts at start of day (v1). User-level `launchd` agents under `~/Library/LaunchAgents/` (v2). Empirical test 2026-05-27 confirms `claude -p` runs cleanly from a launchd user agent without a TTY; the v2 path is technically viable. Client-side IT approval still gates production use |
| Live dashboards | Host-side artifact tool | Dated markdown reports under `PRODUCE-outputs/artifacts/`. Standalone HTML files for anything interactive |
| Skill discovery | Prior host enumerates plugin skills | **Confirmed working** (2026-05-27 empirical test, see Open Questions §1). Claude Code discovers and invokes SKILL.md files from `.claude/skills/{name}/` on bare directories with no plugin manifest. Validation and other workflows can ship as first-class skills |
| File presentation | Host-side file-card tool | Plain markdown links to files in the working folder |
| MCP layer | Prior host's plugin marketplace, many connectors | Zero MCPs at install. Each MCP goes through client IT/InfoSec approval before activation |
| Hook system | Prior host's session-start hook | Claude Code `.claude/hooks/session-start.sh`, generic version that loads `Universal/AGENTS.md` (Claude Code's native cascade handles the root `AGENTS.md`/`CLAUDE.md`), detects which initiative directory pwd is inside, and handles `_archived/` and other lifecycle prefixes correctly |
| File deletion | `mv` to `_trash/` (prior host's sandbox blocks `rm`) | Same convention. Validate per-device whether `rm` is actually blocked; if not, the trash pattern stays anyway for revertibility |
| Cloud-drive sync | All vault state syncs across machines | One-way only. Repo is the deploy artifact, not a sync channel |
| Auth to the repo | Cloud-drive sync handles it | Anonymous HTTPS clone (public repo). No credentials on the client device |

## Soft-partition initiative model

Initiatives are roadmap items the client is shipping (think: a feature build, an experiment, a migration). Each lives in `Initiatives/{slug}/` with the same 5-verb-bucket skeleton (READ-/FOLLOW-/PRODUCE-/RECORD-/RUN-). Templates live at `Universal/`. Completed deliverables live inside the initiative.

Key differences from today's hard-partition model:

- **Visibility.** Initiatives can read each other's content, which helps when two initiatives share patterns or one references the other's research.
- **Default write target.** Sessions auto-detect the active initiative from `pwd`. Writes default into the active initiative. Cross-initiative writes require an explicit path.
- **Promotion.** Initiative-specific artifacts can graduate to `Universal/` when they become reusable (the "1-pager template lives at Universal, completed 1-pager lives in the initiative" pattern). Promotion follows the standard change-protocol sweep.
- **Lifecycle.** Active initiatives sit at `Initiatives/{slug}/`. Completed or paused ones move to `Initiatives/_archived/{slug}/`, per the folder-creation-rules exemption for `_archived/` subfolders.

## Packaging

### Sanitization (aggressive scrub before first commit)

The source vault for the framework typically contains past-client content that cannot ship. (First-run worked example: 40+ files in `Universal/` mentioned past clients by name.) The sanitization pass runs *before* any `git init` happens.

Procedure (audit fixes applied):

1. **Build a staging directory** outside the current vault. Copy in only the framework files: playbooks, voice Layers 1 and 2, skill scaffolds, folder-creation rules, change-protocol.
2. **Run the flag-and-review scanner.** Ripgrep against ~25 patterns covering past-client names, named individuals, regulatory tokens, customer-name leaks, dollar figures over a threshold, email addresses, phone numbers, "internal-only" / "confidential" / "do not share" string matches, and prompt-injection-style strings. Output goes to `_sanitization-staging/flagged.tsv` for review.
3. **Per-file disposition.** The operator reviews `flagged.tsv` row-by-row: accept / redact / drop / escalate. The output is committed as `_sanitization-manifest.md`, a record of what was decided, not what was sensitive.
4. **Generalize what stays.** Every file that survives the scrub gets a second pass. Any reference to a specific client, person, deal, or internal-only fact gets rewritten to its generic equivalent. The doc-sync playbook stays a doc-sync playbook; engagement-specific worked-example asides get dropped.
5. **Verification pass.** A second ripgrep run against the same patterns. Confirms zero hits before any commit.
6. **Manual spot-check** of the top-20 files most likely to retain past-client signal (entities, handoffs, ledgers, exemplars).

The 25-pattern scanner spec is implemented in the `sanitization-scan` skill at `.claude/skills/sanitization-scan/SKILL.md` (step 3 of that skill enumerates the categories).

### Repo structure

```
portable-ai-ecosystem/
├── README.md                       (what this repo is, how to install)
├── INSTALL.md                      (the install runbook, mirrors this playbook §"Install runbook")
├── LICENSE                         (MIT)
├── AGENTS.md                       (generic root rules, no client refs)
├── CLAUDE.md                       (byte-identical sibling per atomic-update rule)
├── .gitignore                      (excludes local state, secrets, hidden framework dirs)
├── scripts/
│   └── bootstrap.sh                (POSIX bash, idempotent, --dry-run flag, audit-fixed)
├── .claude/
│   ├── hooks/
│   │   └── session-start.sh        (generic, soft-partition aware)
│   ├── skills/                     (scaffolds only; skill discovery unverified, see Open Questions)
│   └── settings.json.template      (copied to settings.local.json by bootstrap)
├── Universal/
│   ├── AGENTS.md
│   ├── CLAUDE.md
│   ├── FOLLOW-workflows-and-guides/
│   │   ├── playbooks/              (all generic playbooks, fully scrubbed)
│   │   └── voice/                  (do-not.md + personal.md scrubbed + formats.md + voice.md as empty Layer-3 template)
│   ├── READ-references-and-knowledge/
│   │   ├── concepts/               (generic concept docs only)
│   │   └── frameworks/             (reusable frameworks)
│   ├── PRODUCE-outputs/            (all subfolders + READMEs, no actual outputs)
│   ├── RECORD-decisions/
│   │   └── _index.md               (empty ledger, format-spec only)
│   └── RUN-automations/            (skill registry + scaffolds, no client skills)
└── Initiatives/
    ├── README.md                   (explains the soft-partition model)
    └── _template/                  (ready-to-copy initiative skeleton)
```

### One-way flow (simplified by the public-repo decision)

The client device clones over anonymous HTTPS. No SSH key, no PAT, no credentials of any kind for the GitHub repo live on the device. Push is impossible because there's nothing to push *with*. The deploy-key and sentinel-URL approaches in the original packaging design are no longer needed.

Two operational guardrails remain:

1. **A second-layer `.gitignore` inside `Initiatives/`** gets created on first bootstrap. It ignores all in-progress initiative content. Even if push *were* somehow possible, `git status` shows nothing to add inside `Initiatives/`.
2. **`pull.ff = only`** in the repo's local git config. Future `git pull` runs from the client device will fail fast on any local commit (which shouldn't happen anyway, since the device can't push). This prevents accidental merge commits drifting the local tree.

The personal-GitHub-as-conduit risk is mitigated by-construction: the repo never holds client content, so there's nothing to leak in either direction.

## Install runbook

Step-by-step install on the client device. The standalone version of this runbook ships in the repo as `INSTALL.md`; the version here is the canonical spec. Audit fixes are applied throughout.

### Pre-flight: IT/InfoSec approval ask

Submit upfront, before any install attempt. Itemized request (see `INSTALL.md` for the full vendor/network/data-flow table):

- Claude Code (Anthropic), terminal CLI. Outbound to `api.anthropic.com` on 443
- Anthropic API key, client-issued (already provisioned on the device per Decision 3)
- Git, standard distribution. Outbound to `github.com` on 443 for HTTPS clone
- GitHub.com network access. Read-only HTTPS clone of a public repo
- Terminal access (Terminal.app or iTerm2 if approved)
- Write access to a working folder. `~/{client-slug}-Claude/` recommended, sibling of `Documents/`, easy to wipe
- Optional later: `ripgrep`, `jq`. They speed up sanitization scans and JSON parsing. The bootstrap script works without them.

What is *not* being asked for: admin privileges, Homebrew install, Docker, Node.js system-wide install, SSH key generation, GitHub authentication, any MCP server. List those explicitly to head off the "what else does this need?" loop.

### Steps

1. **Confirm IT approvals are in hand.** Don't begin until Claude Code, git, and GitHub.com network access are all approved. The Anthropic API key was provisioned by the client when the device was issued, so that step is already done.
2. **Verify Claude Code is installed and authenticated.** `which claude` returns a path; `claude --version` returns a version. First `claude` invocation completes auth against the client-issued API key.
3. **Verify git is installed.** `git --version`.
4. **Clone the repo over anonymous HTTPS.** `cd ~ && git clone https://github.com/{your-handle}/portable-ai-ecosystem.git {client-slug}-Claude && cd {client-slug}-Claude`. No credentials, no key setup, no `~/.ssh/config` work.
5. **Run the bootstrap script.** `./scripts/bootstrap.sh`. Creates local-state directories, copies `settings.json.template` to `settings.local.json`, sets `.claude/hooks/session-start.sh` executable, writes the `Initiatives/.gitignore` one-way-flow layer, sets `pull.ff = only` in local git config, and prints next steps. The script is audit-fixed (no `eval "$@"` wrapper bug, no `set -euo pipefail` interactions with ripgrep no-match exits, no SSH config writes since the public-repo decision removed that need).
6. **Confirm Claude Code settings.** `settings.local.json` allowlist includes Read, Write, Edit, Grep, Glob, Bash, WebFetch, WebSearch. The `Write` tool is explicitly enabled in the template.
7. **Run the validation prompt sequence** (next section).
8. **Run `engagement-bootstrap-from-urls.md`** against the client's public URLs to populate brand, voice Layer 3, glossary, thesis. See companion playbook.

## Validation

Skill discovery on bare directories is confirmed working as of 2026-05-27 (see Open Questions §1, resolved). The validation procedure ships both ways:

- **Primary:** a `validate-install` skill (scaffold at `.claude/skills/validate-install/SKILL.md` in the repo). Invoking it walks through the 6-probe checklist below, captures the responses, and writes a dated install-record to `Universal/RECORD-decisions/`.
- **Fallback / spec:** the markdown checklist below remains the human-readable spec. The skill loads it at runtime. If a user prefers to run the checks manually, they read this section directly.

In a fresh `claude` session inside the working folder, run each prompt and verify the response matches the expected shape:

| # | Prompt | Expected response shape |
|---|---|---|
| 1 | "What's the 4-step voice composition rule?" | Claude recalls the four steps from `voice-composition.md`: do-not + personal + formats + project voice |
| 2 | "List the active initiatives." | Claude enumerates `Initiatives/*/` directories with their `README.md` one-liners |
| 3 | "What's the folder-creation rule when I want a new subfolder?" | Claude cites the three rules from `folder-creation-rules.md` |
| 4 | "Try to push to the remote." | Claude reports there's no push credential on the device, so push is impossible. The failure message names the missing credential |
| 5 | "When I run `git pull`, what gets updated and what stays untouched?" | Claude explains the `Initiatives/.gitignore` layer. Framework updates flow; in-progress work stays untouched |
| 6 | (inside an initiative) "I'm about to draft a customer-facing one-pager. Self-attest the voice layers you've loaded." | Claude reports Layer 1 (do-not) + Layer 2 (personal + formats:doc) + Layer 3 (voice.md) loaded, per the four-step rule |

All six green = ecosystem is live. Any red = consult `INSTALL.md` §Troubleshooting.

## Audit findings disposition

194 audit findings across three audits (technical, security, UX). Disposition summary:

| Finding category | Count | Disposition |
|---|---|---|
| Bootstrap script bash bugs (P0) | 12 | **Fixed** in the script that ships in the repo |
| Path inconsistencies between docs (P0) | 4 | **Fixed.** Canonical paths locked: `~/{client-slug}-Claude/` for the working folder, `scripts/bootstrap.sh` for the bootstrap script, `.claude/hooks/session-start.sh` for the hook |
| Claude Code skill discovery unverified (P0) | 1 | **RESOLVED 2026-05-27.** Empirical test confirms skills load from bare `.claude/skills/{name}/SKILL.md` with no plugin manifest. Validation now ships as both a `validate-install` skill (primary) and the markdown checklist (spec). See `empirical-tests/2026-05-27 - Skill Discovery Test Results.md` |
| `Write` tool missing from settings allowlist (P0) | 1 | **Fixed** in `settings.json.template` |
| Hook rewrite not delivered (P0) | 1 | **Fixed.** Generic `session-start.sh` written and ships in the repo. Loads `Universal/AGENTS.md` (cascade gap fill), detects active initiative from pwd including lifecycle-prefixed paths, surfaces an engagement-level reminder when pwd is outside any initiative |
| Personal-GitHub-as-IP-conduit (P0) | 1 | **Mitigated by design.** Sanitization protocol means the repo never holds client content. Risk goes from load-bearing to residual |
| 40+ Universal/ files mention past clients (P0) | 1 | **Resolved by sanitization scrub.** Those files are filtered out or generalized at staging time, never reach the repo |
| `aboutme.md`, entities/, exemplars (P0) | 3 | **Drop, not migrate.** None ship. Layer-3 voice is rebuilt fresh on the client device by `engagement-bootstrap-from-urls.md` |
| `personal.md` disposition (P0) | 1 | **Resolved per Decision 5.** Metadata about Gmail extraction and time-period sourcing scrubbed; voice content ships in the repo |
| SSH-keygen / PAT / deploy-key complexity (P1) | 3 | **Resolved by Decision 1.** Public repo means anonymous HTTPS clone. None of the auth complexity is needed on the client device |
| Meeting-capture pipeline loss (P1) | 1 | **Resolved** by `process-meeting-transcripts.md` (source-agnostic playbook covering native meeting-platform transcription, Otter, Fireflies, manual paste) plus its companion skill draft. Drive-MCP-based automation deferred to v1.1 until client IT approves a Drive MCP |
| Scheduled task replacement reality (P1) | 1 | **v1 = manual morning prompt** ("run the daily review"). v2 = `launchctl` user agents, **technically validated** (empirical test 2026-05-27, see Open Questions §2 resolved). Client IT approval of the launchd workflow gates production rollout |
| Initiative-kickoff workflow missing (P1) | 1 | **Resolved** by `engagement-bootstrap-from-urls.md` (engagement-level bootstrap) and `initiative-kickoff.md` (initiative-level folder setup) plus the matching skill drafts |
| Friday-evening compounding-friction items (P2) | 9 | **Top 5 polished in v1.** The rest deferred to v1.1 |
| MCP attack-surface vetting checklist (P1) | 1 | **Resolved** by `external-tool-approval.md`, which covers MCP servers as Category 1 plus four other tool categories (skills/plugins from public sources, desktop apps, CLI utilities, browser extensions). No separate `mcp-approval-checklist.md` needed |
| Remaining P2/P3 polish | ~140 | **Triaged** against an effort estimate. Roughly 30 worth doing in v1; the rest tracked as ledger entries |

The full audit reports that drove this disposition table live outside the repo in the framework author's working vault. They're not load-bearing for repo users; they document the design history.

## Open questions

Decisions 1-5 resolved 2026-05-27. Two of three empirical questions resolved 2026-05-27. One remains, testable only on the actual client device itself.

1. ~~**Skill discovery on bare directory.**~~ **RESOLVED 2026-05-27.** Empirical test on a personal Mac (Claude Code 2.1.144, Claude Sonnet 4.5) confirms strong positive across all 4 probes: skill auto-discovered, frontmatter parsed, invocation succeeded with exact-match output, file still readable via Read tool. Validation promoted from markdown-checklist-only to skill + markdown spec.
2. ~~**`launchd` headless `claude -p`.**~~ **RESOLVED 2026-05-27.** Empirical test on a personal Mac confirms strong positive: a launchd user agent invoked `claude -p` non-interactively, the run completed without TTY errors or auth blockers, and the expected output was produced. Scheduled-task v2 can rely on launchd directly. Client-side IT approval of the launchd workflow still gates production rollout.
3. **MDM and Gatekeeper on the client device.** Are `chmod +x` and execution of cloned shell scripts blocked by enterprise endpoint security? If yes, the bootstrap script needs an alternative invocation pattern (e.g., `bash scripts/bootstrap.sh` instead of `./scripts/bootstrap.sh`). Only testable on the actual client device; the install runbook treats it as a day-1 test with a known fallback.

## Trustly-specific notes for the first run

Treat this section as a one-off appendix to the generic playbook. Future engagements skip it.

- **Repo:** `https://github.com/cntrout/portable-ai-ecosystem`, public, MIT-licensed.
- **Client device working folder:** `~/Trustly-Claude/`.
- **Anthropic API key:** Trustly-issued, already provisioned on the device.
- **First initiatives to seed once `engagement-bootstrap-from-urls.md` completes:** TBD by Corey based on the first 1-2 weeks of Trustly conversations. Don't pre-create empty initiative folders.
- **First validation run** is also the first stress test of the playbook. Expect to find at least 3-5 issues this audit pass missed. Update this playbook and the research bundle with anything new. The change-protocol sweep applies.

## Cross-references

- Companion playbook for engagement-layer bootstrap: `engagement-bootstrap-from-urls.md`
- Voice composition rule (unchanged on the new device): `voice-composition.md`
- Folder-creation rules (unchanged on the new device): `folder-creation-rules.md`
- Change-protocol sweep (this playbook's edits ran through it): `change-protocol.md`
- Decisions ledger: `Universal/RECORD-decisions/_index.md`

*History: [Universal/RECORD-decisions/_index.md](../../RECORD-decisions/_index.md)*
