---
allowed-tools: Bash, Read, Write, LS
---

# Issue Reopen

Reopen a closed issue.

## Usage
```
/pm:issue-reopen <issue_number> [reason]
```

## Instructions

### 0. Detect Tracker

```bash
source .claude/ccpm.config 2>/dev/null || true
CCPM_TRACKER="${CCPM_TRACKER:-github}"
```

**If `CCPM_TRACKER=linear`**: Follow Step 0L (Linear reopen).
**If `CCPM_TRACKER=github`**: Skip Step 0L, follow existing steps.

### 0L. Linear Issue Reopen

```bash
# Preflight
command -v linear >/dev/null 2>&1 || {
  echo "❌ linear-cli not found. Install: brew install schpet/tap/linear"
  exit 1
}

# Resolve identifier
task_file=".claude/epics/{epic_name}/$ARGUMENTS.md"
linear_id=$(basename "$task_file" .md)
if [[ ! "$linear_id" =~ ^[A-Z]+-[0-9]+$ ]]; then
  linear_id=$(grep '^linear:' "$task_file" | sed 's|.*issue/||' | tr -d '[:space:]')
fi

[ -z "$linear_id" ] && {
  echo "❌ Cannot resolve Linear issue identifier."
  exit 1
}

# Transition to default (Todo) state
linear issue edit "$linear_id" --state "$LINEAR_DEFAULT_STATE"
echo "✅ Linear issue $linear_id set to: $LINEAR_DEFAULT_STATE"

# Update local task frontmatter
current_date=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
[ -f "$task_file" ] && {
  sed -i.bak "s/^status:.*/status: open/" "$task_file"
  sed -i.bak "s/^updated:.*/updated: $current_date/" "$task_file"
  rm -f "${task_file}.bak"
  echo "✅ Local task frontmatter updated: status=open"
}
```

### 1. Find Local Task File

Search for task file with `github:.*issues/$ARGUMENTS` in frontmatter.
If not found: "❌ No local task for issue #$ARGUMENTS"

### 2. Update Local Status

Get current datetime: `date -u +"%Y-%m-%dT%H:%M:%SZ"`

Update task file frontmatter:
```yaml
status: open
updated: {current_datetime}
```

### 3. Reset Progress

If progress file exists:
- Keep original started date
- Reset completion to previous value or 0%
- Add note about reopening with reason

### 4. Reopen on GitHub

```bash
# Reopen with comment
echo "🔄 Reopening issue

Reason: $ARGUMENTS

---
Reopened at: {timestamp}" | gh issue comment $ARGUMENTS --body-file -

# Reopen the issue
gh issue reopen $ARGUMENTS
```

### 5. Update Epic Progress

Recalculate epic progress with this task now open again.

### 6. Output

```
🔄 Reopened issue #$ARGUMENTS
  Reason: {reason_if_provided}
  Epic progress: {updated_progress}%
  
Start work with: /pm:issue-start $ARGUMENTS
```

## Important Notes

Preserve work history in progress files.
Don't delete previous progress, just reset status.