# Universal/READ-references-and-knowledge/evaluation-ledgers/

**Purpose:** Append-only ledgers tracking what tools and concepts the operator has already evaluated. Loaded when the operator asks "has this been looked at?" or "did I already decide on X?" before spending time re-evaluating something the answer already exists for.

## What lives here

- `MASTER-tools.md`: one row per tool the operator has surfaced and assessed. Tracks evaluation status (evaluating, adopted, rejected, deferred), short fit notes, and a re-look trigger if relevant.
- `MASTER-concepts.md`: same shape, for concepts, methodologies, frameworks, or any idea worth tracking through an evaluation lifecycle.
- `DEFERRED-long-form.md`: items pulled out of the master ledgers for later deep evaluation, with re-look timing.

## What does not live here

- The full review or write-up of a tool or concept after evaluation. Those live in `../../PRODUCE-outputs/research/` and the ledger row links to them.
- Per-vendor or per-tool pages with extensive content. The ledger holds the verdict and the link; the substrate lives elsewhere.

## Lifecycle

Accreting. Append-only by design. An item never leaves the ledger; its status changes from "evaluating" to a terminal state (adopted, rejected, deferred) and stays there. Re-evaluations create a new row with a back-reference to the prior one rather than overwriting.

Exempt from staleness checks. The whole point of the ledger is that old entries stay readable as a historical record.

## Naming convention

Three named files at the folder root: `MASTER-tools.md`, `MASTER-concepts.md`, `DEFERRED-long-form.md`. No subfolders, no per-tool pages.

Each row inside a master ledger uses a compact table format with these columns: name, surfaced-on date, status, fit-note, re-look trigger, link to the full review if one exists.

## Cross-references

- `Universal/FOLLOW-workflows-and-guides/playbooks/external-tool-approval.md`: the approval gate that runs before a tool gets added as adopted.
- `Universal/RUN-automations/skills/_index.md`: skills that write to or read from this ledger.
- `Universal/PRODUCE-outputs/research/`: the long-form review write-ups that the ledger rows link to.

## Lifecycle stance for v1.2 first install

On first install the master files ship empty (just headers). The operator populates rows as they encounter tools and concepts during real work. There is no auto-population pipeline in v1.2; entries are added by hand or by future skills that wire into this folder.
