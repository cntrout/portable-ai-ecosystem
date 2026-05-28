#!/bin/bash
# bootstrap.sh: one-time setup script for the portable-ai-ecosystem repo.
#
# Runs after `git clone` on the client device. Idempotent: safe to re-run.
#
# Usage:
#   ./Universal/RUN-automations/scripts/bootstrap.sh           run bootstrap
#   ./Universal/RUN-automations/scripts/bootstrap.sh --dry-run print what would change without doing it
#   ./Universal/RUN-automations/scripts/bootstrap.sh --help    show this message
#
# Exit codes:
#   0  success
#   1  user-input error (bad flag, missing prereq)
#   2  configuration error (file not where expected)
#   3  file-system error (couldn't write)
#
# Audit-driven fixes applied to this script:
#   - No `eval "$@"` wrapper bug. Functions called directly.
#   - No `set -euo pipefail` interaction with grep/rg no-match exits.
#     Uses targeted error handling per-operation instead.
#   - Idempotent: every operation checks prior state before modifying.
#   - Clear exit codes documented above.
#   - POSIX-compatible bash; no bashisms beyond default macOS/Linux bash.

set -e  # Exit on any command failure (no pipefail; we handle pipes case-by-case)

# ---- Globals --------------------------------------------------------------

DRY_RUN=0
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Resolve REPO_ROOT depth-independently via git so this script works regardless
# of where it lives inside the repo (currently `Universal/RUN-automations/scripts/`).
# Fall back to script-relative resolution if git isn't available or this isn't a
# git repo yet (e.g., during initial staging before `git init`).
if command -v git > /dev/null 2>&1 && git -C "$SCRIPT_DIR" rev-parse --show-toplevel > /dev/null 2>&1; then
  REPO_ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
else
  REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
fi
LOG_FILE="$REPO_ROOT/.bootstrap.log"

# ---- Helpers --------------------------------------------------------------

log() {
  local msg="$1"
  echo "[bootstrap] $msg"
  if [ $DRY_RUN -eq 0 ]; then
    echo "$(date '+%Y-%m-%dT%H:%M:%S') $msg" >> "$LOG_FILE"
  fi
}

run() {
  # Run a command unless in dry-run mode. Echoes the command first.
  local cmd_desc="$1"
  shift
  if [ $DRY_RUN -eq 1 ]; then
    echo "[dry-run]  would: $cmd_desc"
  else
    log "$cmd_desc"
    "$@"
  fi
}

usage() {
  cat <<EOF
Usage: $(basename "$0") [--dry-run | --help]

Bootstrap the portable-ai-ecosystem repo on a new client device.

  --dry-run    print what would change without making changes
  --help       show this message

Exit codes:
  0 success
  1 user-input error
  2 configuration error
  3 file-system error
EOF
}

# ---- Argument parsing -----------------------------------------------------

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    --help|-h) usage; exit 0 ;;
    *) echo "[bootstrap] unknown argument: $1"; usage; exit 1 ;;
  esac
  shift
done

# ---- Pre-flight checks ----------------------------------------------------

log "starting bootstrap (repo root: $REPO_ROOT, dry-run: $DRY_RUN)"

# Check that key files exist before we begin
if [ ! -f "$REPO_ROOT/AGENTS.md" ]; then
  echo "[bootstrap] error: $REPO_ROOT/AGENTS.md not found. This script must run from a properly-cloned portable-ai-ecosystem repo."
  exit 2
fi

if [ ! -d "$REPO_ROOT/.claude" ]; then
  echo "[bootstrap] error: $REPO_ROOT/.claude/ not found. This script must run from a properly-cloned portable-ai-ecosystem repo."
  exit 2
fi

# ---- 1. Create local-state directories ------------------------------------

for dir in \
  "$REPO_ROOT/Initiatives" \
  "$REPO_ROOT/Universal/READ-references-and-knowledge/meetings-and-transcripts" \
  "$REPO_ROOT/.claude/_bootstrap-state"
do
  if [ ! -d "$dir" ]; then
    run "create $dir" mkdir -p "$dir"
  else
    log "exists: $dir (skip)"
  fi
done

# ---- 2. Initiatives placeholder index --------------------------------------

if [ ! -f "$REPO_ROOT/Initiatives/_index.md" ]; then
  if [ $DRY_RUN -eq 1 ]; then
    echo "[dry-run]  would: create $REPO_ROOT/Initiatives/_index.md"
  else
    log "create $REPO_ROOT/Initiatives/_index.md"
    cat > "$REPO_ROOT/Initiatives/_index.md" <<'IDXEOF'
# Initiatives/_index.md

Registry of active and archived initiatives in this engagement.

| Slug | Status | Owner | Started | Target ship | One-line scope | Link |
|------|--------|-------|---------|-------------|----------------|------|
IDXEOF
  fi
else
  log "exists: $REPO_ROOT/Initiatives/_index.md (skip)"
fi

# ---- 3. Copy settings.json.template to settings.local.json -----------------

SETTINGS_TEMPLATE="$REPO_ROOT/.claude/settings.json.template"
SETTINGS_LOCAL="$REPO_ROOT/.claude/settings.local.json"

if [ -f "$SETTINGS_TEMPLATE" ]; then
  if [ ! -f "$SETTINGS_LOCAL" ]; then
    run "copy settings template to local" cp "$SETTINGS_TEMPLATE" "$SETTINGS_LOCAL"
  else
    log "exists: $SETTINGS_LOCAL (skip; will not overwrite local edits)"
  fi
else
  log "warning: $SETTINGS_TEMPLATE not found; skipping settings copy"
fi

# ---- 4. Make the session-start hook executable -----------------------------

HOOK="$REPO_ROOT/.claude/hooks/session-start.sh"
if [ -f "$HOOK" ]; then
  if [ ! -x "$HOOK" ]; then
    run "chmod +x $HOOK" chmod +x "$HOOK"
  else
    log "executable: $HOOK (skip)"
  fi
else
  log "warning: $HOOK not found; skipping chmod"
fi

# ---- 5. Write Initiatives/.gitignore (one-way-flow layer) -----------------

INIT_GITIGNORE="$REPO_ROOT/Initiatives/.gitignore"
if [ ! -f "$INIT_GITIGNORE" ]; then
  if [ $DRY_RUN -eq 1 ]; then
    echo "[dry-run]  would: create $INIT_GITIGNORE"
  else
    log "create $INIT_GITIGNORE"
    cat > "$INIT_GITIGNORE" <<'GIEOF'
# Initiatives/.gitignore
#
# Created by bootstrap.sh. Implements the one-way-flow layer documented in
# portable-ai-ecosystem.md §"Packaging" §"One-way flow".
#
# Everything inside this folder is local to the device. Initiative content
# (notes, transcripts, drafts, deliverables) never flows back to the repo.

*
!.gitignore
!_index.md
!README.md
!_template/
!_template/**
GIEOF
  fi
else
  log "exists: $INIT_GITIGNORE (skip)"
fi

# ---- 6. Set local git config: pull.ff = only ------------------------------

if [ -d "$REPO_ROOT/.git" ]; then
  # Check current setting before applying
  current=$(git -C "$REPO_ROOT" config --local pull.ff 2>/dev/null || echo "")
  if [ "$current" != "only" ]; then
    run "set git pull.ff = only" git -C "$REPO_ROOT" config --local pull.ff only
  else
    log "git pull.ff already set to only (skip)"
  fi
else
  log "warning: $REPO_ROOT/.git/ not found; skipping git config (repo not initialized?)"
fi

# ---- 7. Write the bootstrap completion marker -----------------------------
#
# Note: .claude/_bootstrap-state/ holds transient install state and should be
# in the repo's top-level .gitignore (added at staging time). Contents are
# local to the device and never commit.

MARKER="$REPO_ROOT/.claude/_bootstrap-state/bootstrap-completed.txt"
if [ $DRY_RUN -eq 0 ]; then
  echo "$(date '+%Y-%m-%dT%H:%M:%S') bootstrap.sh completed successfully" >> "$MARKER"
  log "wrote completion marker: $MARKER"
fi

# ---- 8. Next-steps pointers ----------------------------------------------

echo ""
echo "==============================================================================="
echo "bootstrap complete."
echo ""
echo "Next steps:"
echo "  1. Run \`claude\` in this directory. The session-start hook should fire and"
echo "     load Universal/AGENTS.md into context."
echo "  2. Invoke the validate-install skill to run the 6-probe check."
echo "  3. Once validation passes, invoke engagement-bootstrap-from-urls to seed"
echo "     the engagement layer from the client's public URLs."
echo ""
echo "Documentation:"
echo "  Main playbook:  Universal/FOLLOW-workflows-and-guides/playbooks/portable-ai-ecosystem.md"
echo "  Install runbook: §\"Install runbook\" in the same playbook"
echo ""
echo "Bootstrap log: $LOG_FILE"
echo "==============================================================================="

exit 0
