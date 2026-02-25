---
allowed-tools: Bash, Read, Write, LS
---

# PRD Sync

Sync PRD content to GitHub as an Epic issue. Creates a new issue or updates an existing one.

## Usage
```
/pm:prd-sync <feature_name>
```

## Preflight

1. **Verify argument provided:**
   - If `$ARGUMENTS` is empty: "❌ Feature name required. Usage: /pm:prd-sync <feature_name>"
   - Stop execution

2. **Verify PRD exists:**
   - Check `.claude/prds/$ARGUMENTS.md` exists
   - If not: "❌ PRD not found: $ARGUMENTS. Create it with: /pm:prd-new $ARGUMENTS"
   - Stop execution

3. **Validate frontmatter:**
   - PRD must have `name`, `status`, `created` fields
   - If invalid: "❌ Invalid PRD frontmatter. Check: .claude/prds/$ARGUMENTS.md"

## Instructions

### 0. Check Remote Repository

Follow `/rules/github-operations.md` — block writes to CCPM template:

```bash
remote_url=$(git remote get-url origin 2>/dev/null || echo "")
if [[ "$remote_url" == *"automazeio/ccpm"* ]] || [[ "$remote_url" == *"automazeio/ccpm.git"* ]]; then
  echo "❌ ERROR: Cannot sync to CCPM template repository!"
  echo "Update your remote: git remote set-url origin https://github.com/YOUR_USERNAME/YOUR_REPO.git"
  exit 1
fi
```

### 1. Detect GitHub Repository

```bash
remote_url=$(git remote get-url origin 2>/dev/null || echo "")
REPO=$(echo "$remote_url" | sed 's|.*github.com[:/]||' | sed 's|\.git$||')
[ -z "$REPO" ] && echo "❌ Cannot detect GitHub repo from git remote" && exit 1
```

### 2. Check If Already Synced

Read PRD frontmatter `github` field:
- If `github` contains a real URL (starts with `https://`), extract issue number for **update mode**
- Extract issue number: `echo "$github_url" | grep -o '[0-9]*$'`
- If `github` is empty, placeholder, or missing → **create mode**

### 3. Strip Frontmatter and Prepare Body

```bash
sed '1,/^---$/d; 1,/^---$/d' .claude/prds/$ARGUMENTS.md > /tmp/prd-body.md
```

### 4. Create or Update GitHub Issue

**Create mode** (no existing `github` field):
```bash
issue_url=$(gh issue create \
  --repo "$REPO" \
  --title "Epic: $ARGUMENTS" \
  --body-file /tmp/prd-body.md \
  --label "epic")
issue_number=$(echo "$issue_url" | grep -o '[0-9]*$')
```

**Update mode** (existing `github` URL):
```bash
gh issue edit $issue_number --repo "$REPO" --body-file /tmp/prd-body.md
```

### 5. Update PRD Frontmatter

Get current datetime: `date -u +"%Y-%m-%dT%H:%M:%SZ"`

Update PRD file frontmatter:
- Set `github: https://github.com/$REPO/issues/$issue_number`
- Only set `status: in-progress` if current status is `backlog` (preserve other statuses like `complete`)
- Set `updated:` to current datetime
- Preserve all other fields (especially `created`)

### 6. Output

**Create mode:**
```
✅ Synced PRD to GitHub: #$issue_number
  - Created: https://github.com/$REPO/issues/$issue_number
  - Label: epic
  - PRD updated with GitHub link

Next: /pm:prd-parse $ARGUMENTS to create implementation epic
```

**Update mode:**
```
✅ Updated GitHub issue: #$issue_number
  - Updated: https://github.com/$REPO/issues/$issue_number
  - PRD body refreshed

Next: /pm:prd-parse $ARGUMENTS to update implementation epic
```

## Error Handling

- If `gh` command fails: "❌ GitHub CLI failed. Run: gh auth login"
- If issue creation fails: report error, don't update frontmatter
- Partial success is fine — report what worked

## Important Notes

- Idempotent — safe to run multiple times
- Only syncs PRD body — does NOT create task sub-issues (use /pm:epic-sync for that)
- Frontmatter is stripped before posting — no internal metadata exposed
- Follow `/rules/strip-frontmatter.md` and `/rules/frontmatter-operations.md`
