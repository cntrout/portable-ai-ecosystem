# Working Context

Read at every session start. **AGENTS.md is canonical** (edit-first, per
the [agents.md](https://agents.md/) open standard). **CLAUDE.md is its
byte-identical first-class sibling** so Claude Code's native cascade
picks up the same content. Edits to one save into the other in the same
change.

## How to work together

- Be proactive. Flag opportunities and risks instead of waiting to be asked.
- Ask before changing files, creating folders, or generating content.
- Teach as you go. Explain the "why" alongside the "what."
- Never fabricate. Ask if you'd otherwise need to assume.
- Chat replies: under 5 sentences unless length is requested. Skip preamble.
- Deliverables: full structure with explicit assumptions and open questions.
- Cite sources for recommendations (file path, transcript reference, data
  query). If inferring rather than citing, say "inferring" explicitly.
- When multiple memory or reasoning symptoms appear during a long
  session, pause and ask the operator before continuing. Pushing through
  is always the operator's call.

## Voice and writing guidelines

Before producing any written output, follow the four-step composition
rule in `Universal/FOLLOW-workflows-and-guides/playbooks/voice-composition.md`.
Load `voice/do-not.md` (Layer 1) and `voice/personal.md` (Layer 2),
plus the relevant section of `voice/formats.md` for the output format.
Add `voice/voice.md` (Layer 3) when the output is customer-facing
(default-on for customer-facing, opt-out for internal-only with
judgment cues in the playbook). All voice files sit under
`Universal/FOLLOW-workflows-and-guides/voice/`. Self-attest the loaded
layers at the top of every chat reply that contains generated written
output.

## File conventions

- All work lives in markdown.
- Dated files use `YYYY-MM-DD - {Descriptive Title}.md`.
- Content folders are visible. Hidden folders are reserved for
  framework-required tooling (`.claude/`, `.git/`, and similar).
- **Deletion** routes through a quarantine pattern: `mv` candidates into
  `_trash/YYYY-MM-DD/<original/path>` with a `_trash/_manifest.md`
  entry. Empty `_trash/` from the file system once approved. Never
  quarantine without explicit per-file approval.

## Folder creation rules

1. Every folder needs a `README.md` or `_index.md` in the same change
   that creates the folder.
2. Never create folders at repo root, at `Universal/` root, or at any
   `Initiatives/{slug}/` root. Nest under existing verb buckets:
   `READ-references-and-knowledge/`, `FOLLOW-workflows-and-guides/`,
   `PRODUCE-outputs/`, `RECORD-decisions/`, `RUN-automations/`.
3. Full rules, exemptions, and enforcement live in
   `Universal/FOLLOW-workflows-and-guides/playbooks/folder-creation-rules.md`.

## Where to look for context

- Active initiative work: `Initiatives/{slug}/`. The session-start hook
  detects which initiative pwd is inside and loads that context.
- Cross-engagement reference (concepts, frameworks, glossary, people,
  thesis): `Universal/READ-references-and-knowledge/`.
- Workflows, playbooks, operating rules:
  `Universal/FOLLOW-workflows-and-guides/`.
- Deliverables: `Universal/PRODUCE-outputs/` for engagement-level
  material, or `Initiatives/{slug}/PRODUCE-outputs/` for initiative-scoped
  artifacts.
- Foundational decisions and history:
  `Universal/RECORD-decisions/_index.md`.
- Skills and automation: `RUN-automations/` for source, or
  `.claude/skills/` for the Claude Code skill directory.

## Soft-partition initiative model

Initiatives are roadmap items the engagement is shipping. Each lives in
`Initiatives/{slug}/` with the standard 5-verb-bucket skeleton.

- **Visibility.** Initiatives can read each other's content, which helps
  when two share patterns or one references another's research.
- **Default write target.** Sessions auto-detect the active initiative
  from pwd. Writes default into the active initiative. Cross-initiative
  writes require an explicit path.
- **Templates live in `Universal/`; deliverables in the initiative.**
  Empty 1-pager template at `Universal/`, completed 1-pager in the
  initiative folder.
- **Promotion.** Initiative-specific artifacts can graduate to
  `Universal/` when they become reusable, following the standard
  change-protocol sweep.

## Edit-time sync rules

Sync at edit time is the primary guard against drift:

- **AGENTS.md and CLAUDE.md**: edit one, save byte-identical content to
  the other in the same change. The session-start hook expects this.
- **Skill and CHANGELOG**: any change under `RUN-automations/skills/{skill}/`
  updates that skill's `CHANGELOG.md` in the same change. One line is
  enough, even for a trivial edit.
- **System-file changes**: trigger the doc-sync ripple sweep in
  `Universal/FOLLOW-workflows-and-guides/playbooks/change-protocol.md`.

*History: [Universal/RECORD-decisions/_index.md](Universal/RECORD-decisions/_index.md)*
