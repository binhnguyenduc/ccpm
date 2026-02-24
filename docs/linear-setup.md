# Linear Setup Guide

This guide explains how to configure CCPM to use [Linear](https://linear.app) as your issue tracker instead of GitHub Issues.

## Prerequisites

### Install linear-cli

**macOS (recommended):**
```bash
brew install schpet/tap/linear
```

**Cross-platform (via Cargo):**
```bash
cargo install linear-cli
```

GitHub: https://github.com/schpet/linear-cli

### Authenticate
```bash
linear auth login
```

Follow the browser prompt to authorize with your Linear workspace. No API tokens to manage — linear-cli stores credentials in your system keychain.

---

## CCPM Setup

Run `/pm:init` and select **"linear"** when prompted for issue tracker:

```
/pm:init
```

The init flow will:
1. Check that `linear` binary is installed
2. Verify you are authenticated (`linear auth login` status)
3. Prompt for your **Linear team key** (e.g. `ENG`, `BACKEND`)
4. Optionally suggest the Linear Claude Code skill
5. Write config to `.claude/ccpm.config`

After init, your `.claude/ccpm.config` will contain:

```bash
export CCPM_TRACKER=linear
export LINEAR_TEAM_ID=ENG
```

---

## Full Workflow Example

```bash
# 1. Create a PRD through guided brainstorming
/pm:prd-new my-feature

# 2. Convert PRD into a technical epic
/pm:prd-parse my-feature

# 3. Break epic into task files
/pm:epic-decompose my-feature

# 4. Push to Linear: creates issues + sets up worktree
/pm:epic-sync my-feature

# 5. Start work on a Linear issue
/pm:issue-start ENG-42

# 6. Push progress updates as Linear comments
/pm:issue-sync ENG-42

# 7. Merge when epic is complete
/pm:epic-merge my-feature
```

> Note: With Linear, issue IDs use the team key prefix (e.g. `ENG-42`) instead of numeric GitHub issue numbers.

---

## Config Variable Reference

| Variable | Description | Default |
|----------|-------------|---------|
| `CCPM_TRACKER` | Issue tracker (`github` or `linear`) | `github` |
| `LINEAR_TEAM_ID` | Your Linear team key (e.g. `ENG`) | _(required)_ |
| `LINEAR_DEFAULT_STATE` | State for new/reopened issues | `Todo` |
| `LINEAR_IN_PROGRESS_STATE` | State when work starts | `In Progress` |
| `LINEAR_DONE_STATE` | State when issue closes | `Done` |

These variables are exported in `.claude/ccpm.config` and sourced automatically by all CCPM scripts.

---

## Security Note

CCPM never stores Linear API tokens or credentials. Authentication is handled entirely by linear-cli using your system keychain.

- Run `linear auth login` once to authenticate
- CCPM reads issue data via the `linear` CLI; no tokens appear in config files
- To revoke access: `linear auth logout`

---

## Troubleshooting

| Error | Fix |
|-------|-----|
| `❌ linear-cli not found` | Install via `brew install schpet/tap/linear` or `cargo install linear-cli` |
| `❌ not authenticated` | Run `linear auth login` |
| `❌ LINEAR_TEAM_ID not set` | Re-run `/pm:init` and enter your team key |
| Issues not appearing | Verify team key matches exactly (case-sensitive, e.g. `ENG` not `eng`) |

---

## Linear Claude Code Skill (Optional)

An optional Claude Code skill provides richer agent-to-Linear integration, including inline issue browsing and creation from the Claude Code interface.

- Check your skill registry for a skill named **"linear"**
- Install it if available: follow the skill's own instructions
- CCPM works fully without the skill — it adds convenience, not required functionality

The skill is suggested automatically during `/pm:init` if detected in your registry.
