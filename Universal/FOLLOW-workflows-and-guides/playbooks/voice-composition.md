---
type: playbook
last_reviewed: 2026-05-28
sync_trigger: 2026-05-28-v1.2-skills-batch
depends-on:
  - playbook:change-protocol
  - playbook:folder-creation-rules
  - playbook:operator-voice-bootstrap
---

# Voice Composition

Assembly rule for applying writing guidelines to ANY output Claude produces
on your behalf. Read at session start (referenced from AGENTS.md), applied
on every output.

The full architecture lives in `Universal/FOLLOW-workflows-and-guides/voice/README.md`. This file is
the *invocation rule*, the procedure Claude follows.

---

## The four-step rule

Before producing written output, Claude:

1. **Always** load `Universal/FOLLOW-workflows-and-guides/voice/do-not.md`
   (Layer 1, universal forbidden patterns)
2. **Always** load `Universal/FOLLOW-workflows-and-guides/voice/personal.md` (Layer 2 baseline) plus
   the relevant section of `Universal/FOLLOW-workflows-and-guides/voice/formats.md` (format augment)
3. **By default** load `Universal/FOLLOW-workflows-and-guides/voice/voice.md` (engagement-layer voice file)
   when the output is customer-facing
   (judgment cues below, default ON, opt out for internal-only)
4. **Self-attest** at the top of the chat reply containing the output:

   ```
   Voice loaded: <comma-separated layers>
   ```

   Examples:
   - `Voice loaded: do-not + personal + slack (internal)`
   - `Voice loaded: do-not + personal + doc:detailed + engagement (customer-facing)`
   - `Voice loaded: do-not + personal + email + engagement (customer-facing)`

   If a layer's source file is a Phase A/B/C placeholder, suffix with
   `:default` to make absence visible:
   - `Voice loaded: do-not + personal:default + email + engagement:default (customer-facing)`

   Self-attestation is **chat-only.** Files written to disk stay clean
   (no voice tag in the file content). Audit happens via the chat thread.

## Judgment cues, internal vs customer-facing

Apply Layer 3 (engagement voice) **by default** when the output is for
external readers. Opt out for output that's clearly internal-only.

**Apply Layer 3 (customer-facing, default ON):**
- Emails to client team or partners
- Docs in the client's Notion / Confluence / Google Docs that team
  members or partners will read
- Ticket descriptions where copy / UX / customer-facing teams engage
- Presentations to client stakeholders
- Public-facing copy written on behalf of the client (LinkedIn posts,
  marketing collateral, release notes for end users)

**Skip Layer 3 (internal-only, opt out):**
- Slack messages to your own collaborators (the consulting team /
  yourself / Claude)
- Internal notes-to-self (research summaries, working memos,
  planning docs)
- Dev tickets with no customer-visible copy ("refactor internal X
  service," "bump dependency Y")
- Working drafts not intended for share in current state
- Output to scratch folders (`outputs/`, `_trash/`, ad-hoc drafts)

**When ambiguous: ask before generating.** Default to asking rather
than guessing. Voice mismatch is annoying; one quick question is cheap.

## Format detection cues

Pick the correct section of `formats.md` based on the output's destination:

| User says... | Format section |
|---|---|
| "Send an email to [person]" / "draft an email to..." | `email` |
| "Reply on Slack" / "draft a Slack message" / "DM [person]" | `slack` |
| "Write a 1-pager / stakeholder update / exec brief" | `doc:concise` |
| "Write a PRD / spec / research synthesis" | `doc:detailed` |
| "Create a Linear ticket / draft a Jira card" | `ticket` |
| "Build a slide / deck / presentation" | `presentation` |

Ambiguous cases, confirm with the user or pick the conservative default
(`doc:concise` if doc is unclear).

## Skill integration

Skills that produce written deliverables should reference this playbook
in their SKILL.md. Specifically:

| Skill | Voice context |
|---|---|
| `initiative-kickoff` | `doc:detailed` variant. Engagement Layer 3 applies, customer-facing. |
| `engagement-bootstrap-from-urls` | `doc:concise` variant. Customer-facing if the bootstrap output is shared with the client; otherwise internal. |
| `operator-voice-bootstrap` | Internal. The output is the regenerated `personal.md` (a structured observations file), not customer-facing content. Layer 3 does not apply. |
| `friction-ledger-capture` | Internal. Append-only operator-facing log; Layer 3 does not apply. |
| `self-improvement-review` | Internal. Propose-only review document for the operator; Layer 3 does not apply. |
| `initial-install` | Internal. Orchestrator status output and the Initial Install record; Layer 3 does not apply. |
| `initial-setup` | Internal. Configuration prompts and ledger row; Layer 3 does not apply. |
| `wire-hooks-and-tasks` | Internal. Plist generation and launchctl status output; Layer 3 does not apply. |

Skills not listed: apply the four-step rule normally based on detected
format and intended audience.

## When a layer is a placeholder

If `personal.md` is the Phase A placeholder (Layer 2 not yet extracted):
- Self-attest with `:default` suffix
- Fall back to neutral senior-PM professional voice
- Lean harder on `do-not.md` and `formats.md`

Same pattern if `Universal/FOLLOW-workflows-and-guides/voice/voice.md` is a placeholder.

## Privacy contract

Personal voice extraction never stores email contents anywhere outside
the user's mail provider. Full contract: `Universal/FOLLOW-workflows-and-guides/voice/README.md` then "Privacy contract."

---

## Self-audit (for Claude)

Before every output, ask:
- [ ] Did I load `do-not.md`?
- [ ] Did I load `personal.md` plus the right `formats.md` section?
- [ ] Did I evaluate customer-facing-ness and load Layer 3 if appropriate?
- [ ] Am I about to write the self-attestation line at the top of the
  reply?

If any answer is no, fix it before sending.

---

*Part of the three-layer voice architecture; see
`Universal/FOLLOW-workflows-and-guides/voice/README.md` for the full system.*
