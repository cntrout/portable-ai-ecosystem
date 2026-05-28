# Initiatives/

Initiatives are the unit of work that ships within an engagement. Each one
gets its own folder under `Initiatives/{slug}/` with the same five-verb-bucket
structure used at the vault root: `FOLLOW-workflows-and-guides/`,
`PRODUCE-outputs/`, `READ-references-and-knowledge/`, `RECORD-decisions/`,
`RUN-automations/`. The structure repeats so the mental model stays
consistent whether you're working at root, engagement, or initiative scope.

Soft partition. When the working directory is inside an initiative folder,
context defaults to that initiative plus the engagement layer plus `Universal/`.
Cross-initiative reads are permitted; writes default to the active
initiative. Hard partitions live at the engagement level (between separate
clients on multi-engagement devices), not between initiatives within an
engagement.

To create a new initiative, follow
`Universal/FOLLOW-workflows-and-guides/playbooks/initiative-kickoff.md`.
The playbook covers slug naming, the folder scaffold, the README templates
for each verb bucket, and the row to add to `_index.md`. Copy
`Initiatives/_template/` as the starting scaffold; the playbook tells you
which sections to fill in and which subfolders to skip when there's no
current content.

The registry lives in `_index.md` next to this file. Sort active initiatives
first, then by start date descending.
