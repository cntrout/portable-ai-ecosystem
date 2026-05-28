#!/bin/bash
# Session-start hook for the portable-ai-ecosystem repo.
#
# Fills the gaps Claude Code's native CLAUDE.md cascade can't reach in the
# soft-partition initiative model.
#
# What Claude Code's native cascade already loads (so this hook does NOT
# duplicate them):
#   - {repo-root}/CLAUDE.md (root)
#   - {repo-root}/Initiatives/{slug}/CLAUDE.md (when pwd is inside an
#     initiative AND that initiative has its own CLAUDE.md, which is rare)
#
# What the cascade CAN'T reach (this hook fills these):
#   - {repo-root}/Universal/AGENTS.md (Universal/ is a sibling of
#     Initiatives/, not a parent, so the cascade never walks into it)
#   - Future hot-cache directory if a memory-compilation system is added
#
# Why AGENTS.md (not CLAUDE.md) for Universal:
#   AGENTS.md is canonical per the agents.md open standard. CLAUDE.md is a
#   byte-identical sibling that the cascade reads when it can. For the
#   Universal layer where the cascade can't reach, the hook reads AGENTS.md
#   directly.
#
# Soft-partition vs hard-partition:
#   Initiatives can read each other (soft partition). Sessions auto-detect
#   the active initiative from pwd; writes default into the active
#   initiative. This hook surfaces the active initiative as a context cue
#   but does not enforce a hard partition.
#
# Voice composition check:
#   If pwd is outside any Initiatives/{slug}/ directory AND the user is
#   likely doing engagement-level work, emit a reminder that the
#   four-step voice composition rule may need explicit invocation.

# ---- Determine repo root (script-relative, not hardcoded) ------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# ---- 1. Universal layer (cascade gap, always loaded) -----------------------

if [ -f "$REPO_ROOT/Universal/AGENTS.md" ]; then
  echo "=== Universal/AGENTS.md ==="
  cat "$REPO_ROOT/Universal/AGENTS.md"
  echo ""
fi

# ---- 2. Universal hot cache (placeholder for future memory/ system) -------

if [ -f "$REPO_ROOT/Universal/READ-references-and-knowledge/memory/hot.md" ]; then
  echo "=== Universal recent-context cache ==="
  cat "$REPO_ROOT/Universal/READ-references-and-knowledge/memory/hot.md"
  echo ""
fi

# ---- 3. Active initiative detection ----------------------------------------

if [[ "$PWD" == *"/Initiatives/"* ]]; then
  # Extract the initiative slug from the path
  INITIATIVE=$(echo "$PWD" | sed -E "s|.*Initiatives/([^/]+).*|\\1|")

  # Handle lifecycle prefixes (_archived/, _shipped/, _completed/) by
  # extracting the actual initiative slug from the next path segment.
  if [[ "$INITIATIVE" == _* ]]; then
    LIFECYCLE="$INITIATIVE"
    INITIATIVE=$(echo "$PWD" | sed -E "s|.*Initiatives/$LIFECYCLE/([^/]+).*|\\1|")
    INITIATIVE_DIR="$REPO_ROOT/Initiatives/$LIFECYCLE/$INITIATIVE"
  else
    INITIATIVE_DIR="$REPO_ROOT/Initiatives/$INITIATIVE"
  fi

  if [ -d "$INITIATIVE_DIR" ]; then
    echo "=== Active initiative: $INITIATIVE ==="
    if [ -f "$INITIATIVE_DIR/README.md" ]; then
      cat "$INITIATIVE_DIR/README.md"
      echo ""
    fi

    # Initiatives rarely have their own AGENTS.md (per initiative-kickoff.md),
    # but if one exists, load it after the README so its rules apply.
    if [ -f "$INITIATIVE_DIR/AGENTS.md" ]; then
      echo "=== Initiative: $INITIATIVE: AGENTS.md ==="
      cat "$INITIATIVE_DIR/AGENTS.md"
      echo ""
    fi

    # Hot cache for the active initiative (placeholder)
    if [ -f "$INITIATIVE_DIR/READ-references-and-knowledge/memory/hot.md" ]; then
      echo "=== Initiative: $INITIATIVE: recent-context cache ==="
      cat "$INITIATIVE_DIR/READ-references-and-knowledge/memory/hot.md"
      echo ""
    fi
  fi
else
  # Not in an initiative directory
  echo "=== Working at engagement level (no active initiative) ==="
  echo ""
  echo "Reminder: voice composition rule applies to written output. The"
  echo "four-step rule loads do-not + personal + formats + (optional)"
  echo "Layer-3 voice. See voice-composition.md for details."
  echo ""
fi
