# CCPM Installation

## Quick Install

```bash
cd path/to/your/project/
curl -sSL https://raw.githubusercontent.com/binhnguyenduc/ccpm/main/install/install.sh | bash
```

Or with wget:

```bash
wget -qO- https://raw.githubusercontent.com/binhnguyenduc/ccpm/main/install/install.sh | bash
```

## Manual Install

```bash
# Clone the repo
git clone --depth 1 https://github.com/binhnguyenduc/ccpm.git /tmp/ccpm

# Copy the payload into your project's .claude/ directory
cp -r /tmp/ccpm/ccpm/* .claude/

# Make scripts executable
chmod +x .claude/scripts/pm/*.sh .claude/scripts/*.sh .claude/hooks/*.sh

# Clean up
rm -rf /tmp/ccpm
```

## What Gets Installed

The installer copies the `ccpm/` directory contents into your project's `.claude/` folder:

```
.claude/
├── agents/        # Sub-agent definitions
├── commands/pm/   # All /pm:* slash commands
├── context/       # Context file system
├── epics/         # Local workspace (gitignored)
├── hooks/         # Claude Code event hooks
├── prds/          # Product requirement docs (gitignored)
├── rules/         # Operational rules
├── scripts/pm/    # Bash scripts backing commands
├── ccpm.config    # Shared config
└── settings.json.example
```

## After Installation

Open Claude Code in your project and run:

```bash
/pm:init
```

This sets up GitHub CLI, authentication, labels, and required directories.
