---
allowed-tools: Bash, Read, Write, LS
---

# Issue Close

Mark an issue as complete and close it on GitHub.

## Usage
```
/pm:issue-close <issue_number> [completion_notes]
```

## Instructions

### 0. Detect Tracker

```bash
source .claude/ccpm.config 2>/dev/null || true
CCPM_TRACKER="${CCPM_TRACKER:-github}"
```

**If `CCPM_TRACKER=linear`**: Follow Step 0L (Linear close), update local frontmatter, done.
**If `CCPM_TRACKER=github`**: Skip Step 0L, follow existing steps.

### 0L. Linear Issue Close

```bash
# Preflight
command -v linear >/dev/null 2>&1 || {
  echo "❌ linear-cli not found. Install: brew install schpet/tap/linear"
  exit 1
}

# Resolve identifier from filename or frontmatter
task_file=".claude/epics/{epic_name}/$ARGUMENTS.md"
linear_id=$(basename "$task_file" .md)
if [[ ! "$linear_id" =~ ^[A-Z]+-[0-9]+$ ]]; then
  linear_id=$(grep '^linear:' "$task_file" | sed 's|.*issue/||' | tr -d '[:space:]')
fi

[ -z "$linear_id" ] && {
  echo "❌ Cannot resolve Linear issue identifier."
  exit 1
}

# Transition to Done state
linear issue edit "$linear_id" --state "$LINEAR_DONE_STATE"
echo "✅ Linear issue $linear_id set to: $LINEAR_DONE_STATE"

# Update local task frontmatter
current_date=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
[ -f "$task_file" ] && {
  sed -i.bak "s/^status:.*/status: closed/" "$task_file"
  sed -i.bak "s/^updated:.*/updated: $current_date/" "$task_file"
  rm -f "${task_file}.bak"
  echo "✅ Local task frontmatter updated: status=closed"
}
```

### 1. Find Local Task File

First check if `.claude/epics/*/$ARGUMENTS.md` exists (new naming).
If not found, search for task file with `github:.*issues/$ARGUMENTS` in frontmatter (old naming).
If not found: "❌ No local task for issue #$ARGUMENTS"

### 2. Update Local Status

Get current datetime: `date -u +"%Y-%m-%dT%H:%M:%SZ"`

Update task file frontmatter:
```yaml
status: closed
updated: {current_datetime}
```

### 3. Update Progress File

If progress file exists at `.claude/epics/{epic}/updates/$ARGUMENTS/progress.md`:
- Set completion: 100%
- Add completion note with timestamp
- Update last_sync with current datetime

### 4. Close on GitHub

Add completion comment and close:
```bash
# Add final comment
echo "✅ Task completed

$ARGUMENTS

---
Closed at: {timestamp}" | gh issue comment $ARGUMENTS --body-file -

# Close the issue
gh issue close $ARGUMENTS
```

### 5. Update Epic Task List on GitHub

Check the task checkbox in the epic issue:

```bash
# Get epic name from local task file path
epic_name={extract_from_path}

# Get epic issue number from epic.md
epic_issue=$(grep 'github:' .claude/epics/$epic_name/epic.md | grep -oE '[0-9]+$')

if [ ! -z "$epic_issue" ]; then
  # Get current epic body
  gh issue view $epic_issue --json body -q .body > /tmp/epic-body.md
  
  # Check off this task
  sed -i "s/- \[ \] #$ARGUMENTS/- [x] #$ARGUMENTS/" /tmp/epic-body.md
  
  # Update epic issue
  gh issue edit $epic_issue --body-file /tmp/epic-body.md
  
  echo "✓ Updated epic progress on GitHub"
fi
```

### 6. Update Epic Progress

- Count total tasks in epic
- Count closed tasks
- Calculate new progress percentage
- Update epic.md frontmatter progress field

### 7. Output

```
✅ Closed issue #$ARGUMENTS
  Local: Task marked complete
  GitHub: Issue closed & epic updated
  Epic progress: {new_progress}% ({closed}/{total} tasks complete)
  
Next: Run /pm:next for next priority task
```

## Important Notes

Follow `/rules/frontmatter-operations.md` for updates.
Follow `/rules/github-operations.md` for GitHub commands.
Always sync local state before GitHub.