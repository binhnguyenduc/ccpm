#!/bin/bash

# Source config for tracker detection
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel 2>/dev/null || echo "$SCRIPT_DIR/../../..")"
config_file="$REPO_ROOT/.claude/ccpm.config"
[ -f "$config_file" ] || echo "⚠️  ccpm.config not found at $config_file — using defaults" >&2
source "$config_file" 2>/dev/null || true

if [ "${CCPM_TRACKER:-github}" = "linear" ]; then
  command -v linear >/dev/null 2>&1 || { echo "❌ linear-cli not found. Install: brew install schpet/tap/linear"; exit 1; }
  [ -z "$LINEAR_TEAM_ID" ] && { echo "❌ LINEAR_TEAM_ID not set. Run: /pm:init"; exit 1; }

  echo ""
  echo "📊 Project Status (Linear — Team: $LINEAR_TEAM_ID)"
  echo "=================================================="
  echo ""
  echo "📝 Open Issues:"
  linear issue list --team "$LINEAR_TEAM_ID" 2>/dev/null || echo "  (none or CLI error)"
  echo ""
else
  echo "Getting status..."
  echo ""
  echo ""


  echo "📊 Project Status"
  echo "================"
  echo ""

  echo "📄 PRDs:"
  if [ -d ".claude/prds" ]; then
    total=$(ls .claude/prds/*.md 2>/dev/null | wc -l)
    echo "  Total: $total"
  else
    echo "  No PRDs found"
  fi

  echo ""
  echo "📚 Epics:"
  if [ -d ".claude/epics" ]; then
    total=$(ls -d .claude/epics/*/ 2>/dev/null | wc -l)
    echo "  Total: $total"
  else
    echo "  No epics found"
  fi

  echo ""
  echo "📝 Tasks:"
  if [ -d ".claude/epics" ]; then
    total=$(find .claude/epics -name "[0-9]*.md" 2>/dev/null | wc -l)
    open=$(find .claude/epics -name "[0-9]*.md" -exec grep -l "^status: *open" {} \; 2>/dev/null | wc -l)
    closed=$(find .claude/epics -name "[0-9]*.md" -exec grep -l "^status: *closed" {} \; 2>/dev/null | wc -l)
    echo "  Open: $open"
    echo "  Closed: $closed"
    echo "  Total: $total"
  else
    echo "  No tasks found"
  fi

  exit 0
fi
