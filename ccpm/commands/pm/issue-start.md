---
allowed-tools: Bash, Read, Write, LS, Task
---

# Issue Start

Begin work on a GitHub issue with parallel agents based on work stream analysis.

## Usage
```
/pm:issue-start <issue_number>
```

## Quick Check

1. **Get issue details:**
   ```bash
   gh issue view $ARGUMENTS --json state,title,labels,body
   ```
   If it fails: "❌ Cannot access issue #$ARGUMENTS. Check number or run: gh auth login"

2. **Find local task file:**
   - First check if `.claude/epics/*/$ARGUMENTS.md` exists (new naming)
   - If not found, search for file containing `github:.*issues/$ARGUMENTS` in frontmatter (old naming)
   - If not found: "❌ No local task for issue #$ARGUMENTS. This issue may have been created outside the PM system."

3. **Check for analysis:**
   ```bash
   test -f .claude/epics/*/$ARGUMENTS-analysis.md || echo "❌ No analysis found for issue #$ARGUMENTS
   
   Run: /pm:issue-analyze $ARGUMENTS first
   Or: /pm:issue-start $ARGUMENTS --analyze to do both"
   ```
   If no analysis exists and no --analyze flag, stop execution.

## Instructions

### 0a. Detect Tracker

```bash
source .claude/ccpm.config 2>/dev/null || true
CCPM_TRACKER="${CCPM_TRACKER:-github}"
```

If `CCPM_TRACKER=linear`: Run Step 0L then continue to parallel agent launch (Steps 1+).
If `CCPM_TRACKER=github`: Skip Step 0L, follow existing Quick Check and Steps.

### 0L. Linear Issue Start

```bash
# Preflight
command -v linear >/dev/null 2>&1 || {
  echo "❌ linear-cli not found. Install: brew install schpet/tap/linear"
  exit 1
}
[ -z "$LINEAR_TEAM_ID" ] && {
  echo "❌ LINEAR_TEAM_ID not set. Run: /pm:init and choose linear."
  exit 1
}

# Resolve task file and Linear identifier
task_file=$(find .claude/epics -name "$ARGUMENTS.md" 2>/dev/null | head -1)
if [ -n "$task_file" ]; then
  linear_id=$(basename "$task_file" .md)
  if [[ ! "$linear_id" =~ ^[A-Z]+-[0-9]+$ ]]; then
    linear_id=$(grep '^linear:' "$task_file" 2>/dev/null | sed 's|.*issue/||' | tr -d '[:space:]')
  fi
fi

[ -z "$linear_id" ] && {
  echo "❌ Cannot resolve Linear issue identifier."
  exit 1
}

# Assign to self and set In Progress state
linear issue update "$linear_id" --assignee self 2>/dev/null \
  && echo "✅ Assigned $linear_id to self" \
  || echo "⚠️  Could not assign $linear_id (check auth: linear auth login)"

linear issue update "$linear_id" --state "$LINEAR_IN_PROGRESS_STATE"
echo "✅ State set to: $LINEAR_IN_PROGRESS_STATE"
```

Note: After Step 0L, continue to the existing worktree check and parallel agent launch (Steps 1+). The parallel agent logic is tracker-agnostic — no changes needed there.

### 1. Ensure Worktree Exists

Check if epic worktree exists:
```bash
# Find epic name from task file
epic_name={extracted_from_path}

# Check worktree
if ! git worktree list | grep -q "epic-$epic_name"; then
  echo "❌ No worktree for epic. Run: /pm:epic-start $epic_name"
  exit 1
fi
```

### 2. Read Analysis

Read `.claude/epics/{epic_name}/$ARGUMENTS-analysis.md`:
- Parse parallel streams
- Identify which can start immediately
- Note dependencies between streams

### 3. Setup Progress Tracking

Get current datetime: `date -u +"%Y-%m-%dT%H:%M:%SZ"`

Create workspace structure:
```bash
mkdir -p .claude/epics/{epic_name}/updates/$ARGUMENTS
```

Update task file frontmatter `updated` field with current datetime.

### 4. Launch Parallel Agents

For each stream that can start immediately:

Create `.claude/epics/{epic_name}/updates/$ARGUMENTS/stream-{X}.md`:
```markdown
---
issue: $ARGUMENTS
stream: {stream_name}
agent: {agent_type}
started: {current_datetime}
status: in_progress
---

# Stream {X}: {stream_name}

## Scope
{stream_description}

## Files
{file_patterns}

## Progress
- Starting implementation
```

Launch agent using Task tool:
```yaml
Task:
  description: "Issue #$ARGUMENTS Stream {X}"
  subagent_type: "{agent_type}"
  prompt: |
    You are working on Issue #$ARGUMENTS in the epic worktree.
    
    Worktree location: ../epic-{epic_name}/
    Your stream: {stream_name}
    
    Your scope:
    - Files to modify: {file_patterns}
    - Work to complete: {stream_description}
    
    Requirements:
    1. Read full task from: .claude/epics/{epic_name}/{task_file}
    2. Work ONLY in your assigned files
    3. Commit frequently with format: "Issue #$ARGUMENTS: {specific change}"
    4. Update progress in: .claude/epics/{epic_name}/updates/$ARGUMENTS/stream-{X}.md
    5. Follow coordination rules in /rules/agent-coordination.md
    
    If you need to modify files outside your scope:
    - Check if another stream owns them
    - Wait if necessary
    - Update your progress file with coordination notes
    
    Complete your stream's work and mark as completed when done.
```

### 5. GitHub Assignment

```bash
# Assign to self and mark in-progress
gh issue edit $ARGUMENTS --add-assignee @me --add-label "in-progress"
```

### 6. Output

```
✅ Started parallel work on issue #$ARGUMENTS

Epic: {epic_name}
Worktree: ../epic-{epic_name}/

Launching {count} parallel agents:
  Stream A: {name} (Agent-1) ✓ Started
  Stream B: {name} (Agent-2) ✓ Started
  Stream C: {name} - Waiting (depends on A)

Progress tracking:
  .claude/epics/{epic_name}/updates/$ARGUMENTS/

Monitor with: /pm:epic-status {epic_name}
Sync updates: /pm:issue-sync $ARGUMENTS
```

## Error Handling

If any step fails, report clearly:
- "❌ {What failed}: {How to fix}"
- Continue with what's possible
- Never leave partial state

## Important Notes

Follow `/rules/datetime.md` for timestamps.
Keep it simple - trust that GitHub and file system work.