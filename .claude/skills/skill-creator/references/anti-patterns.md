# Anti-patterns: skills the skill-creator rejects

Loaded by SKILL.md when an anti-pattern is detected. Each anti-pattern documents: **pattern**, **why it's bad**, **detection**, **suggested alternative**.

Rejected skills go to `.claude/skills/.drafts/{name}/` for iteration, not silent discard.

---

## A1. Writes to AGENTS.md or CLAUDE.md

**Pattern:** Skill's logic includes Edit or Write operations on `AGENTS.md`, `CLAUDE.md`, or any `Initiatives/*/AGENTS.md` / `CLAUDE.md` pair.

**Why bad:** Violates the atomic byte-identity rule. Any unilateral edit drifts the pair.

**Detection:** Grep the SKILL.md body and any helper scripts for the file names.

**Alternative:** Write doc suggestions to `Universal/PRODUCE-outputs/machine-generated/skill-creator/YYYY-MM-DD-doc-suggestion-{skill-name}.md`. A human reviews and applies the change atomically to both files.

**Severity:** BLOCK.

---

## A2. Writes to framework-managed hidden folders

**Pattern:** Skill writes directly to `.git/`, the host's own config folder, or any tool-owned cache directory.

**Why bad:** These folders are tool-managed. Direct writes corrupt indexes and configs.

**Detection:** Grep helper scripts for these paths in write contexts.

**Alternative:**
- Index data: write to a standard markdown path; embedding tools re-embed on save.
- Config: never touch directly; use the tool's documented config mechanism.

Exception: writes to a skill's own `.last-used` counter file are allowlisted because they are owned by the skill-creator counter pattern.

**Severity:** BLOCK.

---

## A3. No trigger phrases in description

**Pattern:** Description says what the skill does without saying when it should trigger.

**Why bad:** Claude under-triggers skills without explicit phrase hints. The description is the routing surface; vague descriptions cause silent misses.

**Detection:** Description lacks any "use this skill when X" or "triggers on Y" pattern.

**Alternative:** Add 5 to 10 concrete phrases the user would type, plus 2 to 3 anti-trigger phrases.

**Severity:** BLOCK.

---

## A4. No exit or skip conditions

**Pattern:** Skill has no documented conditions under which it should NOT run.

**Why bad:** Leads to over-triggering and running the skill in inappropriate contexts.

**Detection:** No "do NOT trigger on", "skip when", or "not for" guidance in description or body.

**Alternative:** Add an explicit "When NOT to use" section with 3 or more concrete cases.

**Severity:** WARN.

---

## A5. Overlapping unresolved triggers

**Pattern:** Skill's trigger phrases overlap heavily with an existing installed skill.

**Why bad:** Ambiguous routing. Claude does not know which to invoke.

**Detection:** Grep `.claude/skills/_index.md` and any installed plugins for phrase overlap.

**Alternative:** Either (a) extend the existing skill rather than create a new one, or (b) make triggers distinguishable, or (c) use `--bypass <rationale>` if a deliberate override.

**Severity:** WARN.

---

## A6. Hardcoded user-home paths

**Pattern:** Skill body or helper scripts include `~/`, `/Users/...`, or other absolute paths that only work on one machine.

**Why bad:** Breaks portability. A framework that ships in a public repo cannot assume a specific user's home directory layout.

**Detection:** Grep for `~/`, `/Users/`, `/home/`, or any other absolute path that includes a username.

**Alternative:** Resolve repo root at runtime via `git rev-parse --show-toplevel`, then build paths relative to that. For paths outside the repo, ask the operator at runtime.

**Severity:** WARN.

---

## A7. Personal or client-specific data in examples or templates

**Pattern:** Skill examples or templates contain real personal names, company names, internal jargon, or other operator-specific context.

**Why bad:** Creates leakage into a framework that may ship publicly. Even for private use, mixing personal context into reusable templates makes them brittle.

**Detection:** Grep for known personal references, project names, internal jargon in examples and templates.

**Alternative:** Use placeholder data (`<ClientName>`, `<PersonName>`, generic numbers). Real examples go in an operator-private folder that the skill references but does not embed.

**Severity:** WARN (BLOCK if obviously a leak of confidential material).

---

## A8. allowed-tools exceeds actual use

**Pattern:** Frontmatter declares tools the skill does not actually call.

**Why bad:** Security hygiene. Skills should have least-privilege tool access.

**Detection:** Grep skill body for tool invocations; compare to `allowed-tools` list.

**Alternative:** Tighten to the exact set used. If the skill might need additional tools in future, request them at use time, not preemptively.

**Severity:** WARN.

---

## A9. version field present but malformed

**Pattern:** A `version` field exists in frontmatter but is not semver, is set to `0.0.0`, or is empty.

**Why bad:** Eval baseline tracking, regression detection, and changelog discipline all require parseable semver if a version is going to be tracked at all.

**Detection:** Parse frontmatter `version` field; validate semver regex.

**Alternative:** Start at `1.0.0`. Increment per the rules:
- Major: enforcement contract changes, breaking behavior
- Minor: new feature, new rule, new capability (backward compatible)
- Patch: bug fix, doc fix, no behavior change

The `version` field is optional; if you do not want to track versions, omit the field entirely rather than leave it malformed.

**Severity:** WARN.

---

## A10. Single-MCP-call wrapper

**Pattern:** Skill's only logic is "call MCP X with these args".

**Why bad:** Adds skill overhead for zero value over invoking the MCP directly.

**Detection:** SKILL.md body has only a single tool call as its core logic.

**Alternative:** Use the MCP directly. If the skill adds value (composition, post-processing, partition awareness, multi-step orchestration), document that value explicitly in the description.

**Severity:** WARN.

---

## A11. Auto-edits framework docs without outbox review

**Pattern:** Skill automatically edits `Universal/FOLLOW-workflows-and-guides/playbooks/`, framework tools registries, or any other framework doc without writing a suggestion to `Universal/PRODUCE-outputs/machine-generated/skill-creator/` first.

**Why bad:** Doc edits should be human-reviewed. Auto-edits cause silent drift and changes that are hard to reverse.

**Detection:** Grep for Write or Edit on framework doc paths.

**Alternative:** All doc changes go through `Universal/PRODUCE-outputs/machine-generated/skill-creator/` for human review.

**Severity:** BLOCK.

---

## Action taxonomy

| Severity | Action |
|---|---|
| **BLOCK** | Refuse to author. Move WIP to `.claude/skills/.drafts/{name}/`. Explain. |
| **WARN** | Surface in chat. Allow `--bypass <reason>` to proceed (logged). |
| **NOTE** | Surface as info, no action required. |

Severity per anti-pattern:
- A1 (AGENTS/CLAUDE writes): BLOCK
- A2 (framework-managed folder writes): BLOCK
- A3 (no trigger phrases): BLOCK
- A4 (no exit conditions): WARN
- A5 (overlapping triggers): WARN
- A6 (hardcoded paths): WARN
- A7 (personal data leak): WARN (BLOCK if confidential)
- A8 (allowed-tools too wide): WARN
- A9 (malformed semver): WARN
- A10 (single-MCP wrapper): WARN
- A11 (auto-doc edits): BLOCK
