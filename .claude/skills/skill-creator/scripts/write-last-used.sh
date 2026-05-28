#!/usr/bin/env bash
# write-last-used.sh: counter-file pattern for retired-skill detection.
#
# Every skill invocation should call this to append a timestamp to its
# own .last-used file. A health-check pass reads these to detect skills
# with no use in 180 or more days (retired candidates).
#
# Usage: write-last-used.sh <skill-path>
#   <skill-path>: absolute path to the skill folder containing SKILL.md
#
# Why this exists: skill invocation telemetry at the platform layer is
# unreliable across hosts. Self-report counters are a workaround for usage
# tracking that does not depend on host-level hooks.
#
# This script is bundled into the framework house template
# (templates/skill-md-skeleton.md), so every new skill auto-self-reports.

set -u

if [[ $# -lt 1 ]]; then
    echo "ERROR: usage: write-last-used.sh <skill-path>" >&2
    exit 1
fi

SKILL_PATH="$1"
COUNTER_FILE="$SKILL_PATH/.last-used"
TIMESTAMP=$(date -Iseconds)

# Append-only, never truncate (preserves usage history for trend analysis)
echo "$TIMESTAMP" >> "$COUNTER_FILE"

# Light-touch rotation: keep last 1000 entries to avoid unbounded growth.
# A 1000-entry log is roughly a 3-year history at 1 use per day, sufficient
# for retired-skill detection.
LINE_COUNT=$(wc -l < "$COUNTER_FILE")
if [[ "$LINE_COUNT" -gt 1000 ]]; then
    tail -n 1000 "$COUNTER_FILE" > "$COUNTER_FILE.tmp" && mv "$COUNTER_FILE.tmp" "$COUNTER_FILE"
fi
