# Universal/PRODUCE-outputs/artifacts/

**Purpose:** Live HTML artifacts (dashboards, comparison views, interactive whiteboards) that the operator opens in a browser to read or interact with. These pull or render data at view time rather than at write time, so they stay current without manual edits.

## What lives here

One subfolder per artifact, each containing the artifact's `index.html` and any supporting assets. For example:

- `ecosystem-overview/`: high-level view of skills, plugins, and connectors on this instance.
- `scheduled-tasks-dashboard/`: current state of any scheduled tasks (next run, last run, cadence).

The folder ships empty on first install. Operators create artifacts on demand using the skill or playbook appropriate to the artifact.

## What does not live here

- Static images, diagrams, screenshots, or exported PDFs belong in `../assets/` instead.
- Markdown writing, research write-ups, and long-form documents belong in `../research/` or `../writing/`.
- Interactive widgets that get displayed inline in a chat reply (not saved to disk) are not artifacts in this sense; they live ephemerally in the conversation.

## Lifecycle

Each artifact subfolder is one-shot at the artifact level but accreting at the version level. The artifact itself stays in place once created; its content updates over time.

Each artifact gets a `versions/` subfolder for history snapshots. The folder-creation-rules playbook exempts `versions/` subfolders from the standard README requirement because they are auto-generated history. The first time an artifact creates a snapshot, the `versions/` folder appears alongside the artifact's `index.html`.

## Naming convention

Subfolder names use kebab-case slugs that describe what the artifact shows. `index.html` is the canonical entry point; supporting CSS, JS, or data files live alongside it inside the same subfolder. Snapshots inside `versions/` use the dated filename convention `YYYY-MM-DD - {state-label}.html`.

## Cross-references

- `Universal/FOLLOW-workflows-and-guides/playbooks/folder-creation-rules.md`: the `versions/` subfolder exemption rule lives here.
- `Universal/PRODUCE-outputs/assets/`: for static files that are not interactive artifacts.

## Lifecycle stance for v1.2 first install

The folder ships empty with this README only. No artifact ships with the v1.2 repo because every artifact is operator-specific. Once the operator builds the first artifact, the `versions/` convention activates on its first snapshot.
