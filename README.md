# portable-ai-ecosystem

A portable, version-controlled framework for running an AI workflow on a locked-down client device that allows only Claude Code in a terminal. Clone the repo over anonymous HTTPS, run one bootstrap script, point it at the client's public URLs, and you have a working AI ecosystem with voice rules, folder conventions, playbooks, and skills already in place.

The repo ships the framework. Your engagement content stays on your device and never flows back.

## Glossary

A few terms recur throughout the framework. Quick definitions so the rest of the README reads cleanly:

- **Engagement.** A unit of consulting or contractor work with one client (a contract, a project, a phase). One engagement per device under the soft-partition model. Inside an engagement, work is broken into "initiatives" (specific roadmap items being shipped).
- **Initiative.** A specific roadmap item the engagement is shipping. Each initiative lives under `Initiatives/{slug}/` with its own 5-bucket folder skeleton. Initiatives are the working unit; the engagement is the container.
- **Operator.** The human running the framework (developer, consultant, PM). The framework is written in operator-second-person voice ("you").
- **Layer 3 voice.** The engagement-specific brand voice file at `Universal/FOLLOW-workflows-and-guides/voice/voice.md`. Ships empty; gets populated by the `engagement-bootstrap-from-urls` skill from the client's public URLs.
- **Universal layer.** Cross-engagement content under `Universal/`: playbooks, voice files, frameworks, the decisions ledger. Reusable from one engagement to the next.

## Who this is for

Third-party developers and consultants working on managed laptops where the security posture is tight:

- Contractors in fintech, healthcare, or other regulated industries whose client device blocks desktop apps, admin installs, and most MCP servers
- Employees at enterprises that restrict AI tooling to a CLI plus an approved API endpoint
- Anyone who wants a portable, version-controlled AI workflow they can stand up on a fresh machine in under an hour

If your client device allows Claude Code in a terminal, allows outbound HTTPS to `github.com` and `api.anthropic.com`, and has git installed, this framework works.

If you have a full developer setup with admin access, Cowork, Claude Desktop, and a bag of MCPs, this framework still works, but you're using a fraction of what's available to you. Consider it a baseline.

## What's in the box

**Playbooks** (`Universal/FOLLOW-workflows-and-guides/playbooks/`). The specs. Each playbook is a markdown document that describes a recurring workflow: how to bootstrap a new engagement from a set of public URLs, how to kick off a new initiative, how to run the change-protocol sweep when you edit a system file, how folder creation works. Twelve playbooks ship in v1.2: `portable-ai-ecosystem`, `engagement-bootstrap-from-urls`, `process-meeting-transcripts`, `initiative-kickoff`, `external-tool-approval`, `voice-composition`, `folder-creation-rules`, `change-protocol`, `initial-install`, `operator-voice-bootstrap`, `voice-personal-scrub-check`, and `change-protocol-sweep-triggers`.

**Skills** (`.claude/skills/`). The runtime. A skill is a `SKILL.md` file with frontmatter that Claude Code auto-discovers and invokes. Thirteen skills ship in v1.2: `initial-install` (the orchestrator), `validate-install`, `initial-setup`, `engagement-bootstrap-from-urls`, `operator-voice-bootstrap`, `wire-hooks-and-tasks`, `sanitization-scan`, `initiative-kickoff`, `process-meeting-transcripts`, `change-protocol-sweep`, `skill-creator`, `friction-ledger-capture`, and `self-improvement-review`. `external-tool-approval` is a playbook, not a skill; it lives under `Universal/FOLLOW-workflows-and-guides/playbooks/`.

**Scripts** (`Universal/RUN-automations/scripts/` and `.claude/hooks/`). The plumbing. A POSIX bash bootstrap script (idempotent, with a `--dry-run` flag) sets up local state on first clone. A session-start hook detects which initiative you're working in based on `pwd` and loads the right context.

**Voice templates** (`Universal/FOLLOW-workflows-and-guides/voice/`). Three voice files plus an empty Layer-3 template. Layer 1 (`do-not.md`) is universal forbidden patterns. Layer 2 (`personal.md` + `formats.md`) is the writer's baseline voice and per-format rules (email, Slack, doc, ticket, presentation). Layer 3 (`voice.md`) ships as an empty template that the engagement bootstrapper fills with the client's brand voice.

**Folder framework**. Five verb buckets at the top of `Universal/` and inside each initiative:

- `READ-references-and-knowledge/` for context Claude reads
- `FOLLOW-workflows-and-guides/` for playbooks, rules, voice templates
- `PRODUCE-outputs/` for deliverables and artifacts
- `RECORD-decisions/` for the decisions ledger
- `RUN-automations/` for skills and scheduled task surfaces

The verb prefix tells you what the folder is *for* at a glance.

**Change-protocol** (`Universal/FOLLOW-workflows-and-guides/playbooks/change-protocol.md`). When you edit a system file (AGENTS.md, CLAUDE.md, a playbook, a voice layer), the change-protocol runs a doc-sweep: find every dependent file, update cross-references, log the decision. Prevents the slow rot where the spec and the code drift apart.

**Folder-creation rules** (`Universal/FOLLOW-workflows-and-guides/playbooks/folder-creation-rules.md`). Three rules that keep the tree from sprawling. Every new folder gets a `README.md` or `_index.md` in the same change. Folders nest under the verb buckets, not at the root. The rules document covers the exemptions and the enforcement path.

## Quick start

The full runbook lives in `INSTALL.md`. The short version:

1. **Verify prerequisites.** `git --version` returns a version. `claude --version` returns a version. Your Anthropic API key is configured (Claude Code's first-run auth handles this).
2. **Clone the repo.** `git clone https://github.com/cntrout/portable-ai-ecosystem.git ~/ai-workspace && cd ~/ai-workspace`.
3. **Run the bootstrap script.** `bash Universal/RUN-automations/scripts/bootstrap.sh`. It creates local-state directories, copies `settings.json.template` to `settings.local.json`, marks the hook executable, writes the `Initiatives/.gitignore` one-way-flow layer, and sets `pull.ff = only` in local git config. The script is idempotent. Re-runs are safe.
4. **Validate.** Open a `claude` session in the working folder and run the `validate-install` skill, or walk through the six-probe checklist in `INSTALL.md`. All six green means the ecosystem loaded correctly.
5. **Run the orchestrator.** Invoke `/initial-install`. It walks you through the remaining seven phases (tool installation, optional MCP activation, hooks and scheduled tasks, per-device config, voice customization, optional engagement bootstrap, final validation) and persists progress to `.claude/_install-state/state.json` so you can pause and resume across sessions. The orchestrator delegates to `initial-setup`, `operator-voice-bootstrap`, `wire-hooks-and-tasks`, and `engagement-bootstrap-from-urls` at the appropriate states. Manual operators who prefer to skip the orchestrator can run those sub-skills directly.

After step 5, you're working. Create your first initiative under `Initiatives/{slug}/` using the `_template/` scaffold, and you're shipping.

## How it works

**The verb-bucket framework.** Every folder at the top of `Universal/` and inside each initiative starts with a verb prefix: READ-, FOLLOW-, PRODUCE-, RECORD-, RUN-. The prefix tells you what the folder is *for* at a glance. When Claude needs to recall context, it looks in READ-. When it needs a rule, it looks in FOLLOW-. When it writes a deliverable, it goes to PRODUCE-. When it records a decision, it goes to RECORD-. When it invokes a skill, it goes to RUN-. The convention is enough to keep a 200-file vault navigable without an index, and it makes the folder-creation rules easy to enforce because every new folder has an obvious parent.

**The soft-partition initiative model.** Roadmap items live under `Initiatives/{slug}/` with the same 5-bucket skeleton. Initiatives can read each other's content, which helps when one initiative references another's research or when a pattern that started in one is worth promoting to a reusable template at `Universal/`. The active initiative is auto-detected from `pwd` at session start, and writes default into it. Cross-initiative writes require an explicit path so accidents don't happen. Completed or paused initiatives move to `Initiatives/_archived/{slug}/`. The soft partition replaces the hard per-client partition used in multi-client setups, because the device this framework targets is single-client by construction (one client managed laptop, one client's work on it).

For a worked example: imagine a fintech engagement with two roadmap items, "Build v2.1 widget" and "Rename payment-method experiment." Each lives in its own `Initiatives/{slug}/` directory. When `pwd` is inside the widget initiative, that initiative's context loads. Open a new terminal tab inside the rename experiment and the rename context loads. Move both to `_archived/` when they ship.

**The voice composition rule.** Before producing any written output, Claude loads four layers in order. Layer 1 (`do-not.md`) is the universal floor of forbidden patterns. Layer 2a (`personal.md`) is the writer's baseline voice. Layer 2b (the relevant section of `formats.md`, indexed by output type: email, Slack, doc-concise, doc-detailed, ticket, presentation) is per-format rules. Layer 3 (`voice.md`, populated by the engagement bootstrapper) is the client's brand voice, loaded only when the output is customer-facing. Claude self-attests the loaded layers at the top of every reply that contains generated written output, so you can see at a glance whether the right layers loaded. The composition rule lives at `Universal/FOLLOW-workflows-and-guides/playbooks/voice-composition.md`.

**The change-protocol.** Any edit to a system file (AGENTS.md, CLAUDE.md, a playbook, a voice layer, a folder rule) triggers a doc-sweep. The protocol enumerates dependent files, updates cross-references in the same change, and logs a one-line entry to the decisions ledger at `Universal/RECORD-decisions/_index.md`. The result is that the spec and the implementation stay byte-aligned over months. Without this, the typical failure mode is that you edit a playbook, forget to update the three files that reference it, and six weeks later a contributor follows stale guidance. The protocol lives at `Universal/FOLLOW-workflows-and-guides/playbooks/change-protocol.md`.

## Repo structure

```
portable-ai-ecosystem/
├── README.md                       (this file)
├── INSTALL.md                      (full install runbook)
├── LICENSE                         (MIT)
├── AGENTS.md                       (root rules, agents.md standard)
├── CLAUDE.md                       (byte-identical sibling of AGENTS.md)
├── .gitignore
├── .claude/
│   ├── hooks/
│   │   └── session-start.sh        (soft-partition aware)
│   ├── skills/                     (scaffolds for v1.2 skills)
│   └── settings.json.template
├── Universal/
│   ├── AGENTS.md
│   ├── CLAUDE.md
│   ├── FOLLOW-workflows-and-guides/
│   │   ├── playbooks/              (change-protocol, folder-rules, voice-composition, etc.)
│   │   └── voice/                  (do-not.md, personal.md, formats.md, voice.md template)
│   ├── READ-references-and-knowledge/
│   │   ├── concepts/
│   │   └── frameworks/
│   ├── PRODUCE-outputs/            (subfolders with READMEs, no content shipped)
│   ├── RECORD-decisions/
│   │   └── _index.md               (empty ledger, format-spec only)
│   └── RUN-automations/
│       ├── scripts/
│       │   └── bootstrap.sh        (idempotent, --dry-run flag)
│       └── skills/                 (skill registry + scaffolds)
└── Initiatives/
    ├── README.md                   (explains the soft-partition model)
    └── _template/                  (ready-to-copy initiative skeleton)
```

## Customizing

To adapt the framework for a new engagement, run the `engagement-bootstrap-from-urls` skill from inside your working folder. Pass it the client's public URLs (homepage, brand page, about page, product pages); it populates voice Layer 3, the glossary, the brand assets folder, and a starter thesis from publicly available content only.

Anything that isn't on the public web stays off the device until you put it there yourself. The bootstrapper is deliberately conservative about what it ingests; the playbook at `Universal/FOLLOW-workflows-and-guides/playbooks/engagement-bootstrap-from-urls.md` documents what gets fetched and what gets generated.

## Data and privacy

The framework targets consultants in fintech, healthcare, and other regulated industries who need to disclose data flows to IT or InfoSec. Here's what flows where:

**What Anthropic Claude sees:** the prompts you type, the file contents Claude reads into context during a session (any file you reference, the session-start hook injection, files pulled by skills), and any web content fetched via `WebFetch` or `WebSearch`. Standard Anthropic enterprise data-handling terms apply per your account's plan.

**What stays local:** everything else. Your full filesystem (Claude only sees files it's explicitly directed to read), your terminal output, your local git state, your `Initiatives/` work, your `settings.local.json`, and anything Claude writes to disk during a session.

**Framework telemetry:** none. The framework collects no analytics, no usage data, no error reports. It does not phone home. There is no embedded tracking, no opt-in or opt-out telemetry toggle, because there is nothing to toggle.

**Network destinations:** `api.anthropic.com` (Claude Code) and `github.com` (read-only anonymous HTTPS for `git clone` and `git pull`). Nothing else.

**Optional MCPs:** if you install MCP connectors beyond the baseline, each has its own data flow. The `external-tool-approval` playbook at `Universal/FOLLOW-workflows-and-guides/playbooks/external-tool-approval.md` documents the per-MCP vetting checklist (vendor, data scope, network destinations, approval gate). The baseline framework does not install any MCPs.

## Status

**v1.0** released 2026-05-27. **v1.1** released 2026-05-28. **v1.2** released 2026-05-28.

Stable in v1.2:

- Verb-bucket folder framework
- Voice Layers 1 and 2 (do-not.md, personal.md, formats.md)
- Voice Layer 3 as an empty template
- Soft-partition initiative model
- Change-protocol and folder-creation rules
- Bootstrap script (POSIX bash, idempotent, audit-fixed)
- Session-start hook (soft-partition aware, lifecycle-prefix safe)
- Thirteen v1.2 skills: `initial-install` (orchestrator), `validate-install`, `initial-setup`, `engagement-bootstrap-from-urls`, `operator-voice-bootstrap`, `wire-hooks-and-tasks`, `sanitization-scan`, `initiative-kickoff`, `process-meeting-transcripts`, `change-protocol-sweep`, `skill-creator`, `friction-ledger-capture`, `self-improvement-review`
- Validation via the `validate-install` skill plus a six-probe markdown checklist as fallback
- Per-device configuration via the `initial-setup` skill
- Self-improvement loop: `friction-ledger-capture` (Phase 1, daily-ish capture) plus `self-improvement-review` (Phase 2, cadence-based pattern review)
- Resumable first-install orchestrator (`initial-install`) with `.claude/_install-state/state.json` progress tracking
- Generic framework tools catalog at `Universal/tools.md` (5 Tier 0, 7 Tier 1, 9 Tier 2 tools, 10 MCPs)

New in v1.2 (since v1.1):

- 3 new skills: `initial-install` (orchestrator), `operator-voice-bootstrap`, `wire-hooks-and-tasks`
- 4 new playbooks: `initial-install.md`, `operator-voice-bootstrap.md`, `voice-personal-scrub-check.md`, `change-protocol-sweep-triggers.md`
- Generic `Universal/tools.md` framework tools catalog
- State-file participation pattern: `initial-install` owns `.claude/_install-state/state.json`; `validate-install`, `initial-setup`, and `engagement-bootstrap-from-urls` participate as co-operative writers when the orchestrator is active
- 9 accidental-gap patches: scaffolds added for `READ-references-and-knowledge/glossary/`, `READ-references-and-knowledge/evaluation-ledgers/`, `READ-references-and-knowledge/configs/`, `PRODUCE-outputs/handoffs/`, `PRODUCE-outputs/artifacts/`, `RUN-automations/scheduled-tasks/`, and the skills `_index.md` registry
- `initial-setup` config schema extended with `friction_ledger.capture_cadence` + `time_of_day` and `self_improvement_review.time_of_day`

New in v1.1 (since v1.0):

- `RUN-automations/` moved to its conceptual home under `Universal/`; `scripts/` consolidated under `Universal/RUN-automations/scripts/`
- 4 new skills migrated from the framework author's prior ecosystem: `skill-creator`, `friction-ledger-capture`, `self-improvement-review`, `initial-setup`
- Skill-drafts restructured from flat to nested directories so multi-file skill packages fit cleanly

Planned for v1.3:

- `workspace-health-check` skill migration (substantial: 19-pass audit framework, leaner pass set targeted for the portable framework)
- Scheduled-task templates shipped under `Universal/RUN-automations/scheduled-tasks/` for the recurring framework skills (the v1.2 folder scaffold ships empty; templates land in v1.3)
- Meeting-transcript automation via approved MCP connectors (today's path is a source-agnostic manual playbook)
- A handful of the Friday-evening polish items from the v1 audit deferral queue

## License and attribution

MIT License. Copyright 2026 Corey Trout. See `LICENSE` for the full text.

The repo follows the [agents.md](https://agents.md/) open standard for the root `AGENTS.md` cascade, with `CLAUDE.md` as a byte-identical sibling so Claude Code's native cascade loads correctly.

## Contributing

External commits are not accepted on the canonical repo. **Fork it** to adapt for your own use. Full posture and rationale in `CONTRIBUTING.md`.

What's welcome on the canonical repo:

- **Issues** for bug reports, documentation clarity problems, or compatibility issues. See `CONTRIBUTING.md` for the issue types that work and the ones that get closed.
- **Security concerns**. See `SECURITY.md`.

What's not accepted: pull requests of any kind, feature requests outside the framework's design, voice-rule disputes. Each of these has a clear answer: fork it.

The spec for the framework as a whole lives in `Universal/FOLLOW-workflows-and-guides/playbooks/portable-ai-ecosystem.md`. Read it before forking heavily.

Voice rules apply to documentation. Layer 1 (`Universal/FOLLOW-workflows-and-guides/voice/do-not.md`) is the floor: no em dashes, no banned vocabulary (delve, leverage, harness, robust, scalable, foster, underscore, pivotal, and the rest of the list), no antithesis abuse, no asyndetic tricolons. The rules are short and applied consistently.

For code (bootstrap script, hooks, skills), the bar is: POSIX bash where possible, idempotent, with a `--dry-run` flag for anything destructive.
