#!/usr/bin/env bash
# preflight.sh: run blocking and warning checks before any skill authoring work.
#
# Usage: preflight.sh <mode> [<skill-name>]
#   <mode>: create | improve | eval | benchmark | describe
#   <skill-name>: required for improve/eval/benchmark/describe; optional for create
#
# Exit codes:
#   0: all checks passed
#   1: blocking failure
#   2: warnings only

set -u

# Resolve repo root via git, fall back to pwd
if [[ -z "${REPO_ROOT:-}" ]]; then
    if REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null); then
        :
    else
        REPO_ROOT="$PWD"
        echo "WARN: not inside a git repo, falling back to PWD as repo root: $REPO_ROOT" >&2
    fi
fi

if [[ ! -d "$REPO_ROOT" ]]; then
    echo "ERROR: Could not locate a usable repo root. Set REPO_ROOT explicitly." >&2
    exit 1
fi

MODE="${1:-}"
SKILL_NAME="${2:-}"

if [[ -z "$MODE" ]]; then
    echo "ERROR: usage: preflight.sh <mode> [<skill-name>]" >&2
    exit 1
fi

WARNINGS=()
BLOCKERS=()

# Check 1: Repo-root AGENTS.md byte-identical to CLAUDE.md (BLOCKING)
check_root_byte_identity() {
    local agents="$REPO_ROOT/AGENTS.md"
    local claude="$REPO_ROOT/CLAUDE.md"
    if [[ ! -f "$agents" ]] && [[ ! -f "$claude" ]]; then
        # Neither file present, no check needed
        return
    fi
    if [[ ! -f "$agents" ]] || [[ ! -f "$claude" ]]; then
        BLOCKERS+=("Repo-root AGENTS.md or CLAUDE.md missing but the other exists")
        return
    fi
    if ! cmp -s "$agents" "$claude"; then
        BLOCKERS+=("Repo-root AGENTS.md and CLAUDE.md byte-identity DRIFT. Fix before authoring (canonical: AGENTS.md). Run: diff $agents $claude")
    fi
}

# Check 2: Each initiative AGENTS.md byte-identical to CLAUDE.md (BLOCKING)
check_initiatives_byte_identity() {
    if [[ ! -d "$REPO_ROOT/Initiatives" ]]; then
        return
    fi
    while IFS= read -r -d '' init_dir; do
        local agents="$init_dir/AGENTS.md"
        local claude="$init_dir/CLAUDE.md"
        if [[ -f "$agents" ]] && [[ -f "$claude" ]]; then
            if ! cmp -s "$agents" "$claude"; then
                local init_name=$(basename "$init_dir")
                BLOCKERS+=("Initiatives/$init_name/ AGENTS.md and CLAUDE.md byte-identity DRIFT")
            fi
        fi
    done < <(find "$REPO_ROOT/Initiatives" -maxdepth 1 -mindepth 1 -type d -print0)
}

# Check 3: pwd partition alignment (WARN)
check_partition_alignment() {
    local cwd="$PWD"
    if [[ "$cwd" == *"$REPO_ROOT/Initiatives/"* ]]; then
        local init_segment=${cwd#*"$REPO_ROOT/Initiatives/"}
        local init_name=${init_segment%%/*}
        WARNINGS+=("pwd is inside Initiatives/$init_name/, any skill authored here will be assumed scoped to $init_name unless overridden")
    fi
}

# Check 4: Skill name validity (WARN for naming nits, BLOCK on collision)
check_skill_name() {
    if [[ -z "$SKILL_NAME" ]]; then
        return
    fi
    if [[ ! "$SKILL_NAME" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]]; then
        WARNINGS+=("Skill name '$SKILL_NAME' is not kebab-case (lowercase alphanumerics plus hyphens only)")
    fi
    if [[ ${#SKILL_NAME} -gt 40 ]]; then
        WARNINGS+=("Skill name '$SKILL_NAME' exceeds 40 chars")
    fi
    if [[ "$SKILL_NAME" == *-skill ]]; then
        WARNINGS+=("Skill name '$SKILL_NAME' has redundant '-skill' suffix")
    fi
    # Uniqueness check (only matters for create mode)
    if [[ "$MODE" == "create" ]]; then
        if [[ -d "$REPO_ROOT/.claude/skills/$SKILL_NAME" ]]; then
            BLOCKERS+=("Skill folder .claude/skills/$SKILL_NAME/ already exists. Choose a different name or use mode=improve")
        fi
    fi
}

# Run checks
check_root_byte_identity
check_initiatives_byte_identity
check_partition_alignment
check_skill_name

# Report
if [[ ${#BLOCKERS[@]} -gt 0 ]]; then
    echo "============================================================"
    echo "PREFLIGHT FAILED: BLOCKING ISSUES"
    echo "============================================================"
    for blocker in "${BLOCKERS[@]}"; do
        echo "  x $blocker"
    done
    echo ""
    if [[ ${#WARNINGS[@]} -gt 0 ]]; then
        echo "Additional warnings:"
        for warning in "${WARNINGS[@]}"; do
            echo "  ! $warning"
        done
    fi
    exit 1
fi

if [[ ${#WARNINGS[@]} -gt 0 ]]; then
    echo "============================================================"
    echo "PREFLIGHT PASSED WITH WARNINGS"
    echo "============================================================"
    for warning in "${WARNINGS[@]}"; do
        echo "  ! $warning"
    done
    exit 2
fi

echo "PREFLIGHT OK: all checks passed"
exit 0
