# Universal/READ-references-and-knowledge/configs/

**Purpose:** Per-engagement configuration files that the framework's skills read at runtime. These are not skill source code (skills live in `.claude/skills/`); they're declarative configuration the operator authors and skills consume.

**What lives here:**

- `meeting-transcript-inbox.md` (ships in v1.2): contract describing the inbox folder layout for `process-meeting-transcripts`. The operator sets the inbox path in `.claude/_setup-state/config.json` via the `initial-setup` skill; this file documents what the inbox folder should look like and how transcripts get picked up.

**Lifecycle:** accreting reference. Config docs land here when a skill needs a declarative per-engagement contract. They stay until the skill is retired.

**Naming:** kebab-case, one file per skill that needs an external config contract.

**What does NOT live here:**

- Skill source code (under `.claude/skills/`)
- Per-device local config (under `.claude/_setup-state/`)
- Engagement-level glossary, thesis, or people roster (those live in sibling `Universal/READ-references-and-knowledge/` folders)
- Universal frameworks or concepts (those live in their own siblings)

**Cross-references:**

- `Universal/FOLLOW-workflows-and-guides/playbooks/process-meeting-transcripts.md` consumes `meeting-transcript-inbox.md`
- `Universal/FOLLOW-workflows-and-guides/playbooks/initial-install.md` documents per-device config file locations
