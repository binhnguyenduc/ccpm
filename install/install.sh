#!/bin/bash
set -e

REPO_URL="https://github.com/binhnguyenduc/ccpm.git"
CLAUDE_DIR=".claude"

echo ""
echo " ██████╗ ██████╗██████╗ ███╗   ███╗"
echo "██╔════╝██╔════╝██╔══██╗████╗ ████║"
echo "██║     ██║     ██████╔╝██╔████╔██║"
echo "╚██████╗╚██████╗██║     ██║ ╚═╝ ██║"
echo " ╚═════╝ ╚═════╝╚═╝     ╚═╝     ╚═╝"
echo ""
echo "Claude Code Project Management Installer"
echo "========================================="
echo ""

# Check prerequisites
if ! command -v git >/dev/null 2>&1; then
  echo "❌ git is required but not installed."
  echo "   Install it from: https://git-scm.com"
  exit 1
fi

# Create temp directory with cleanup trap
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

echo "📦 Downloading CCPM..."
if ! git clone --depth 1 --quiet "$REPO_URL" "$TEMP_DIR" 2>/dev/null; then
  echo "❌ Failed to clone CCPM repository."
  echo "   Check your internet connection and try again."
  exit 1
fi

# Copy payload to .claude/
echo "📂 Installing to ${CLAUDE_DIR}/..."
mkdir -p "$CLAUDE_DIR"

# Clean managed directories to remove stale files from previous installs
for dir in agents commands context hooks rules scripts; do
  rm -rf "${CLAUDE_DIR:?}/$dir"
done

cp -r "$TEMP_DIR/ccpm/"* "$CLAUDE_DIR/"

# Make scripts executable
chmod +x "$CLAUDE_DIR/scripts/pm/"*.sh 2>/dev/null || true
chmod +x "$CLAUDE_DIR/scripts/"*.sh 2>/dev/null || true
chmod +x "$CLAUDE_DIR/hooks/"*.sh 2>/dev/null || true

echo ""
echo "✅ CCPM installed successfully!"
echo ""
echo "Installed to: ${CLAUDE_DIR}/"
echo ""
echo "Next step: Open Claude Code in your project and run:"
echo "  /pm:init"
echo ""
