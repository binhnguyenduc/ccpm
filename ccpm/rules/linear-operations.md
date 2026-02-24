# Linear Operations Rule

Standard patterns for `linear` CLI operations across all commands.

## CRITICAL: Preflight Check

**Before ANY Linear operation, verify linear-cli is installed and team is configured:**

```bash
# Check linear-cli is installed
command -v linear >/dev/null 2>&1 || {
  echo "❌ linear-cli not found."
  echo "Install: brew install schpet/tap/linear"
  echo "Or:      cargo install linear-cli"
  echo "See:     https://github.com/schpet/linear-cli"
  exit 1
}

# Check LINEAR_TEAM_ID is set
[ -z "$LINEAR_TEAM_ID" ] && {
  echo "❌ LINEAR_TEAM_ID not set. Run: /pm:init and choose Linear."
  exit 1
}
```

This check MUST be performed in ALL commands that:
- Create issues (`linear issue create`)
- Update issues (`linear issue update`)
- Comment on issues (`linear issue comment add`)
- Any other operation that modifies Linear data

## Authentication

linear-cli manages its own authentication. Do not store API tokens in config files.

```bash
# If unauthenticated, linear-cli commands will fail with a clear message.
# Instruct user to run: linear auth login
linear team list >/dev/null 2>&1 || {
  echo "❌ linear-cli not authenticated. Run: linear auth login"
  exit 1
}
```

## Common Operations

### View Issue
```bash
linear issue view "{identifier}"
```

### Create Issue
```bash
# Always specify team to avoid defaulting to wrong workspace
issue_id=$(linear issue create \
  --team "$LINEAR_TEAM_ID" \
  --title "{title}" \
  --description "{body}")
# Returns the issue identifier (e.g. ENG-42)
echo "Created: $issue_id"
```

### Create Sub-Issue (with parent)
```bash
issue_id=$(linear issue create \
  --team "$LINEAR_TEAM_ID" \
  --title "{title}" \
  --description "{body}" \
  --parent "{parent_identifier}")
```

### Add Comment
```bash
# ALWAYS check LINEAR_TEAM_ID first!
linear issue comment add "{identifier}" --body "{comment_body}"
```

### Update State
```bash
# ALWAYS check LINEAR_TEAM_ID first!
# State names are team-specific — use values from LINEAR_IN_PROGRESS_STATE, LINEAR_DONE_STATE, LINEAR_DEFAULT_STATE
linear issue update "{identifier}" --state "{state_name}"
```

### Assign to Self
```bash
linear issue update "{identifier}" --assignee self
```

## Error Handling

If any linear command fails:
1. Show clear error: "❌ Linear CLI failed: {command}"
2. Check: is linear-cli installed? Is the user authenticated? Is LINEAR_TEAM_ID correct?
3. Do not retry automatically

## Important Notes

- **ALWAYS** check `LINEAR_TEAM_ID` is set before any write operation
- Issue identifiers follow `{TEAM_KEY}-{NUMBER}` format (e.g. `ENG-42`)
- linear-cli does not use `--json` flag; parse plain text output when needed
- `linear issue create` outputs the identifier followed by a URL (e.g. `ENG-42 https://...`); extract ID with `| grep -oE '[A-Z]+-[0-9]+' | head -1`
- State names must exactly match your Linear team's workflow states
- Keep operations atomic — one linear command per action
- `--description` accepts inline text only; truncate large bodies to ~4000 chars to avoid shell ARG_MAX limits
