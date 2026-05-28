# Universal/READ-references-and-knowledge/glossary/

**Purpose:** Shared terminology for this instance of the framework. Acronyms, internal nicknames, project codenames, and any term that appears in two or more places and benefits from a single canonical definition. Loaded as substrate when the operator asks "what does X mean?" or when a skill needs to resolve a shorthand reference.

## What lives here

- `_index.md`: the actual glossary content. One alphabetized list of terms, each with a one or two sentence definition. Stays in one file rather than per-term subfiles so the registry stays scannable.

## What does not live here

- Initiative-scoped terminology that only matters inside one initiative belongs in `Initiatives/{slug}/READ-references-and-knowledge/glossary.md` instead.
- Structured concept definitions with examples, related ideas, and full prose explanations belong in `../concepts/`. The glossary is for short lookups, not full essays.
- Named people and organizations live in `../entities/`, not here.

## Lifecycle

Accreting. Append-only growth in practice; terms rarely come out (mark deprecated rather than delete). Add a term once it shows up in two or more contexts and a reader could plausibly hit it without knowing what it means.

## Naming convention

Single `_index.md` file holds the full glossary. Terms inside the file appear alphabetically, with the term in bold followed by the definition on the same line or directly under it. No per-term subfiles.

## Cross-references

- `Universal/FOLLOW-workflows-and-guides/playbooks/engagement-bootstrap-from-urls.md`: writes the initial glossary entries when an engagement gets activated from public URLs.
- `Universal/FOLLOW-workflows-and-guides/playbooks/folder-creation-rules.md`: covers the README requirement for this folder.
- `Initiatives/{slug}/READ-references-and-knowledge/glossary.md`: initiative-scoped equivalent when terminology only matters inside one initiative.
