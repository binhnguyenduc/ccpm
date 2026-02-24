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
  echo "🎯 Next Issue (Linear — Team: $LINEAR_TEAM_ID)"
  echo "=============================================="
  echo ""
  # List unstarted issues (state = LINEAR_DEFAULT_STATE, default: "Todo")
  linear issue list --team "$LINEAR_TEAM_ID" --state "${LINEAR_DEFAULT_STATE:-Todo}" 2>/dev/null | head -5 \
    || linear issue list --team "$LINEAR_TEAM_ID" 2>/dev/null | head -5 \
    || echo "  (none or CLI error)"
  echo ""
else
  echo "Getting status..."
  echo ""
  echo ""

  echo "📋 Next Available Tasks"
  echo "======================="
  echo ""

  # Find tasks that are open and have no dependencies or whose dependencies are closed
  found=0

  for epic_dir in .claude/epics/*/; do
    [ -d "$epic_dir" ] || continue
    epic_name=$(basename "$epic_dir")

    for task_file in "$epic_dir"/[0-9]*.md; do
      [ -f "$task_file" ] || continue

      # Check if task is open
      status=$(grep "^status:" "$task_file" | head -1 | sed 's/^status: *//')
      if [ "$status" != "open" ] && [ -n "$status" ]; then
        continue
      fi

      # Check dependencies
      # Extract dependencies from task file
      deps_line=$(grep "^depends_on:" "$task_file" | head -1)
      if [ -n "$deps_line" ]; then
        deps=$(echo "$deps_line" | sed 's/^depends_on: *//')
        deps=$(echo "$deps" | sed 's/^\[//' | sed 's/\]$//')
        # Trim whitespace and handle empty cases
        deps=$(echo "$deps" | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
        [ -z "$deps" ] && deps=""
      else
        deps=""
      fi

      # If no dependencies or empty, task is available
      if [ -z "$deps" ] || [ "$deps" = "depends_on:" ]; then
        task_name=$(grep "^name:" "$task_file" | head -1 | sed 's/^name: *//')
        task_num=$(basename "$task_file" .md)
        parallel=$(grep "^parallel:" "$task_file" | head -1 | sed 's/^parallel: *//')

        echo "✅ Ready: #$task_num - $task_name"
        echo "   Epic: $epic_name"
        [ "$parallel" = "true" ] && echo "   🔄 Can run in parallel"
        echo ""
        ((found++))
      fi
    done
  done

  if [ $found -eq 0 ]; then
    echo "No available tasks found."
    echo ""
    echo "💡 Suggestions:"
    echo "  • Check blocked tasks: /pm:blocked"
    echo "  • View all tasks: /pm:epic-list"
  fi

  echo ""
  echo "📊 Summary: $found tasks ready to start"

  exit 0
fi
