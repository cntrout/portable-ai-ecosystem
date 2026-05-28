---
type: playbook
last_reviewed: 2026-05-28
sync_trigger: 2026-05-28-v1.2-skills-batch
depends-on:
  - playbook:change-protocol
---

# Folder Creation Rules

**Status:** Active rule. Enforced across all sessions.
**Authoritative source:** Root `AGENTS.md` / `CLAUDE.md`, `## Folder creation rules` section.
**Workspace-health-check pass:** the nightly README-coverage check (when the health-check skill is installed).

This playbook expands the three folder-creation rules into actionable detail.

---

## Rule 1, no folder without docs

Every folder in the vault must contain **either** `README.md` **or** `_index.md`. When Claude creates a new folder during work, the documentation file is part of the **same commit**, not a follow-up. The folder doesn't ship without its docs.

### When to use which file

- **`README.md`**, describes *what the folder is for*. Purpose, contents, lifecycle, references. Most folders use this. Use the template in section 4 below.
- **`_index.md`**, used when the folder's content IS a registry, ledger, or index. Examples: `Universal/RECORD-decisions/_index.md` (append-only decisions ledger), `Initiatives/_index.md` (engagement registry), `RUN-automations/skills/_index.md` (skill catalog). A folder with `_index.md` doesn't also need `README.md`.

### Exemptions

The following folders **do not require** README.md or _index.md:

- **Dated subfolders** matching `YYYY-MM-DD/` or `YYYY-MM-DD_<slug>/`, auto-generated buckets (for example, `_trash/2026-05-26/`, `Scheduled/{task-slug}/runs/2026-05-17_*/`).
- **Lifecycle subfolders** with leading underscore: `_archived/`, `_shipped/`, `_completed/`, `_deprecated/`, `_evals/`, `_drafts/`.
- **`runs/`** subfolders under scheduled tasks, auto-generated output buckets.
- **`versions/`** subfolders under live artifacts, auto-generated history snapshots of HTML dashboards.
- **Framework directories** dictated by external tooling: `.claude/`, `.obsidian/`, `.smart-env/`, `.health-check/`, `.claude-plugin/`, `__pycache__/`, `.pytest_cache/`, `.tmp.*/`.
- **`_trash/`** itself and its dated children, quarantine has its own conventions (`_manifest.md`, `_proposed.md`).
- **Single-file directories** like `Universal/RECORD-decisions/` when the contained file is the `_index.md` itself (the file IS the documentation).

If a folder fits an exemption, Claude doesn't need to create a README. The health-check pass uses the same exemption list when auditing coverage.

### What counts as a "valid" README

Stub READMEs (less than 250 bytes, boilerplate-only "see ../CLAUDE.md") count as **missing** for enforcement purposes. The README must explain:
- **What the folder is for** (one sentence)
- **What lives here** (specific item types, not "stuff")
- **What does NOT live here** (with pointers to adjacent locations)
- **Lifecycle** (does content accrete, cycle, ship, or stay permanent?)

The template in section 4 enforces all four.

---

## Rule 2, the nightly README-coverage check enforces coverage

The README-coverage check runs nightly as part of the workspace-health-check orchestrator (when installed). The pass:

1. Walks every content folder in the vault, applying the exemption list from section 1 above.
2. For each non-exempt folder, checks for `README.md` OR `_index.md` (case-insensitive).
3. If neither exists, **WARN** finding: `Missing README at <path>`.
4. If `README.md` exists but is at most 250 bytes and matches stub patterns, **WARN** finding: `Stub README at <path>, needs expansion to meet rule 1`.
5. Repeat findings persisting more than 7 consecutive runs escalate to **CRITICAL**.

Findings surface in run-chat for triage. Claude or the user can address them by writing the missing README using the section 4 template.

Pass implementation lives at `RUN-automations/skills/workspace-health-check/scripts/passes/` (filename: the README-coverage pass).

---

## Rule 3, never create folders at any root level

**The protected roots:**
- Vault root: `<vault-root>/`
- Universal root: `<vault-root>/Universal/`
- Every initiative root: `<vault-root>/Initiatives/{slug}/`

### Decision tree for new folders

```
Need a new home for content?
|
+-- Can an existing folder hold this?
|   +-- YES, use the existing folder. STOP.
|   +-- NO, continue
|
+-- Does the new folder fit under an existing verb bucket?
|   +-- READ-references-and-knowledge/   (consumed during work)
|   +-- FOLLOW-workflows-and-guides/     (rules that govern work)
|   +-- PRODUCE-outputs/                 (created during work)
|   +-- RECORD-decisions/                (foundational ledger)
|   +-- RUN-automations/                 (execution surfaces, vault root only)
|   +-- YES, create the new folder nested under that bucket. STOP.
|   +-- NO, continue
|
+-- Is this a sanctioned exception?
    +-- Restructure with explicit decisions-ledger entry, permitted
    +-- New initiative (creates Initiatives/{slug}/), permitted
    +-- Otherwise, ASK before proceeding. Default is no.
```

### Why the rule

The verb framework partitions content by relationship to a working session. Adding folders at root level **outside the framework** breaks the partitioning logic, both for humans navigating the vault and for AI agents reading paths as structural cues.

If a folder doesn't fit under any verb bucket, that's a signal that either:
- (a) The content actually fits somewhere; look again.
- (b) The content represents a new category that warrants a structural decision, which requires a decisions-ledger entry and explicit approval, not an unilateral folder creation.

---

## 4. Standard README Template

Every README starts with this skeleton. Adapt for the specific folder.

```markdown
# {Folder Name (path-relative)}

**Purpose:** One sentence describing what this folder is for.

**Mirrors:** (only for verb-bucket folders) `Universal/{counterpart}/`, same verb framework, this scope.

**What lives here:**
- Specific item type 1 (example file pattern)
- Specific item type 2
- ...

**What does NOT live here:**
- Adjacent concept 1, lives in `{path}/` because {reason}
- Adjacent concept 2, lives in `{path}/` because {reason}

**Lifecycle:**
- Active state: where new content enters
- Graduation/archival: how content moves out (if it does, name the subfolder)
- Quarantine policy: when content gets sent to `_trash/`

**Naming conventions:**
- Filename format: `YYYY-MM-DD - {Title}.md` (or whatever applies)
- Special files: `_index.md`, `README.md`, `_handoff-template.md`, ...

**Referenced by:**
- Skill / scheduled task / playbook that reads or writes this folder

**Cross-references:**
- See also `{related/folder/}` for {related concept}
```

Length: aim for at most 60 lines / roughly 250 to 500 words. Longer is fine if the folder is unusual; shorter is fine if the folder is simple.

---

## 5. Worked examples

### 5.1 New folder created during work

The user says "let's start a new analysis area for the checkout funnel." Claude's response sequence:

1. **Check existing buckets.** Does `Initiatives/{slug}/PRODUCE-outputs/research-and-analysis/analyses/` already work? Yes, just add a new file inside, no folder needed.
2. If a folder IS needed (say, a multi-doc workstream): create `Initiatives/{slug}/PRODUCE-outputs/research-and-analysis/checkout-funnel/` (verb bucket, existing parent, new specific folder).
3. **In the same commit, create `README.md` inside the new folder** using the section 4 template.
4. Never create `Initiatives/{slug}/CheckoutFunnel/` at initiative root.

### 5.2 Auto-generated dated bucket

A daily scheduled task creates `Scheduled/{task-slug}/runs/2026-05-27_some-output-slug/`. This folder:
- Is dated (matches `YYYY-MM-DD_*` pattern), exempt from README requirement
- Is under an existing parent (`runs/`), satisfies rule 3
- The parent `runs/` folder has its own README explaining the dated-subfolder convention

### 5.3 Sanctioned restructure

A vault restructure creates several new top-level folders (`RUN-automations/`) and verb-bucket folders inside Universal/ and initiatives. Permitted because:
- It's recorded in the decisions ledger (`Universal/RECORD-decisions/_index.md`)
- A recommendation doc plus migration runbook provide the rationale
- The user approved before execution

### 5.4 New initiative

Spinning up `Initiatives/{slug}/` (when a new engagement converts from pre-engagement to active) creates a new initiative root folder. Permitted by the initiative-template exception in rule 3. The bootstrap creates all 5 verb buckets plus standard initiative files (README, AGENTS, CLAUDE, _index, action-items).

---

## 6. What to do if the rule conflicts with the request

If the user asks Claude to create a folder that violates rule 3 (new root-level folder), Claude:
1. **Flag the conflict.** "That folder would land at vault root; the rule says new folders go under existing verb buckets."
2. **Suggest the verb-bucket placement.** Name the verb that fits and the specific path.
3. **Wait for confirmation.** If the user insists, treat as a sanctioned exception, write a decisions-ledger entry capturing the rationale, then proceed.

If the rule isn't sure which verb bucket fits (genuine ambiguity), ASK before creating.

---

*Authoritative summary in root `AGENTS.md` / `CLAUDE.md`.*
*Decisions ledger reference: `Universal/RECORD-decisions/_index.md`.*
