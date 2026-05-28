#!/usr/bin/env python3
"""
inject-custom-frontmatter.py: preserve custom frontmatter fields across a
skill-improve cycle (a description optimizer can strip non-standard fields).

Custom fields preserved by default:
    - partition-scope
    - lifecycle-state
    - replaced-by
    - compatibility (custom shape if any)
    - any field listed in CUSTOM_FIELDS below

Usage:
    inject-custom-frontmatter.py --snapshot <skill-path>
        Reads SKILL.md frontmatter, writes custom fields to
        /tmp/skill-frontmatter-<name>.json. Idempotent.

    inject-custom-frontmatter.py --restore <skill-path>
        Reads /tmp/skill-frontmatter-<name>.json, re-injects fields into
        SKILL.md frontmatter (under the upstream-written fields). Verifies
        write and surfaces any new fields the optimizer added so the user
        can decide whether to keep them.
"""

import argparse
import json
import re
import sys
from pathlib import Path

CUSTOM_FIELDS = [
    "partition-scope",
    "lifecycle-state",
    "replaced-by",
    "compatibility",
    # Add more here as the framework evolves
]

FRONTMATTER_RE = re.compile(r"^---\n(.*?)\n---\n", re.DOTALL)


def parse_frontmatter(text):
    """Parse YAML-ish frontmatter from SKILL.md into dict. Naive but sufficient
    for flat scalar fields. For nested fields (compatibility), keeps the raw
    YAML block as a string."""
    m = FRONTMATTER_RE.match(text)
    if not m:
        return {}, text
    frontmatter_text = m.group(1)
    body = text[m.end():]
    fields = {}
    current_key = None
    current_block_lines = []
    for line in frontmatter_text.split("\n"):
        if not line.strip():
            continue
        kv_match = re.match(r"^([a-zA-Z][a-zA-Z0-9_-]*)\s*:\s*(.*)$", line)
        if kv_match and not line.startswith(" ") and not line.startswith("\t"):
            if current_key is not None and current_block_lines:
                fields[current_key] = "\n".join(current_block_lines)
                current_block_lines = []
            key, value = kv_match.group(1), kv_match.group(2).strip()
            if value:
                fields[key] = value
                current_key = None
            else:
                current_key = key
                current_block_lines = []
        elif current_key is not None:
            current_block_lines.append(line)
    if current_key is not None and current_block_lines:
        fields[current_key] = "\n".join(current_block_lines)
    return fields, body


def serialize_frontmatter(fields):
    """Serialize fields dict back to YAML-ish frontmatter text."""
    lines = []
    for key, value in fields.items():
        if "\n" in str(value):
            lines.append(f"{key}:")
            for sub in str(value).split("\n"):
                lines.append(sub)
        else:
            lines.append(f"{key}: {value}")
    return "\n".join(lines)


def snapshot(skill_path):
    skill_md = Path(skill_path) / "SKILL.md"
    if not skill_md.exists():
        print(f"ERROR: {skill_md} does not exist", file=sys.stderr)
        sys.exit(1)
    text = skill_md.read_text()
    fields, _ = parse_frontmatter(text)
    custom = {k: v for k, v in fields.items() if k in CUSTOM_FIELDS}
    if not custom:
        print(f"No custom fields to snapshot for {skill_path}", file=sys.stderr)
        return
    skill_name = fields.get("name", Path(skill_path).name)
    snapshot_path = Path(f"/tmp/skill-frontmatter-{skill_name}.json")
    snapshot_path.write_text(json.dumps(custom, indent=2))
    print(f"Snapshotted {len(custom)} custom fields to {snapshot_path}")
    for k, v in custom.items():
        print(f"  - {k}: {v[:60] if isinstance(v, str) else v}")


def restore(skill_path):
    skill_md = Path(skill_path) / "SKILL.md"
    if not skill_md.exists():
        print(f"ERROR: {skill_md} does not exist", file=sys.stderr)
        sys.exit(1)
    text = skill_md.read_text()
    fields, body = parse_frontmatter(text)
    skill_name = fields.get("name", Path(skill_path).name)
    snapshot_path = Path(f"/tmp/skill-frontmatter-{skill_name}.json")
    if not snapshot_path.exists():
        print(f"ERROR: no snapshot at {snapshot_path}", file=sys.stderr)
        sys.exit(1)
    custom = json.loads(snapshot_path.read_text())

    new_custom_fields = [k for k in fields if k in CUSTOM_FIELDS and k not in custom]
    stripped_custom_fields = [k for k in custom if k not in fields]

    # Re-inject: custom fields go after upstream-managed fields, preserving order
    for k, v in custom.items():
        fields[k] = v

    new_frontmatter = serialize_frontmatter(fields)
    new_text = f"---\n{new_frontmatter}\n---\n{body}"
    skill_md.write_text(new_text)

    print(f"Restored {len(custom)} custom fields to {skill_md}")
    if stripped_custom_fields:
        print(f"  ! Optimizer stripped these fields (now re-injected): {stripped_custom_fields}")
    if new_custom_fields:
        print(f"  i Optimizer added these new custom-looking fields (kept as-is): {new_custom_fields}")
    snapshot_path.unlink()


def main():
    p = argparse.ArgumentParser()
    g = p.add_mutually_exclusive_group(required=True)
    g.add_argument("--snapshot", metavar="SKILL_PATH", help="Snapshot custom fields before Improve")
    g.add_argument("--restore", metavar="SKILL_PATH", help="Restore custom fields after Improve")
    args = p.parse_args()
    if args.snapshot:
        snapshot(args.snapshot)
    elif args.restore:
        restore(args.restore)


if __name__ == "__main__":
    main()
