#!/usr/bin/env bash
#
# One-time setup: installs the `enclawd` command (a symlink into this clone —
# keep the clone; `git pull` is how you get updates). Installs Claude Code if
# it's missing. Safe to re-run; re-running is the standard "fix my setup" step.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$HOME/.local/bin"

# Preflight
for cmd in git curl python3; do
  command -v "$cmd" >/dev/null || { echo "setup: '$cmd' is required but not installed." >&2; exit 1; }
done
if ! command -v aws >/dev/null; then
  echo "setup: AWS CLI v2 is required. Install it first:" >&2
  echo "  https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html" >&2
  exit 1
fi
if ! git ls-remote git@github.com:Engram-Robotics-Company/claude-plugins.git >/dev/null 2>&1; then
  echo "setup: WARNING — can't reach git@github.com:Engram-Robotics-Company/claude-plugins.git over SSH."
  echo "setup: check your GitHub SSH key; company skills/MCP servers won't load until this works."
fi

# Install Claude Code if missing (stable channel — trails latest by ~a week)
if ! command -v claude >/dev/null; then
  echo "setup: installing Claude Code (stable)..."
  curl -fsSL https://claude.ai/install.sh | bash -s stable
fi

# Install the enclawd command
mkdir -p "$BIN_DIR"
chmod +x "$REPO_DIR/bin/enclawd"
ln -sf "$REPO_DIR/bin/enclawd" "$BIN_DIR/enclawd"
echo "setup: linked $BIN_DIR/enclawd -> $REPO_DIR/bin/enclawd"

# Make sure ~/.local/bin is on PATH
case ":$PATH:" in
  *":$BIN_DIR:"*) ;;
  *)
    rc="$HOME/.bashrc"
    [ "$(basename "${SHELL:-bash}")" = "zsh" ] && rc="$HOME/.zshrc"
    line='export PATH="$HOME/.local/bin:$PATH"'
    grep -qxF "$line" "$rc" 2>/dev/null || printf '\n%s\n' "$line" >> "$rc"
    echo "setup: added ~/.local/bin to PATH in $rc — open a new shell (or 'source $rc')."
    ;;
esac

cat <<'EOF'

Done. What's left (one-time):

  1. enclawd doctor    # opens a browser to sign in to AWS if needed, then
                       # verifies AWS -> Bedrock -> Claude end to end
  2. enclawd           # company Claude; plain `claude` stays personal
  3. Inside enclawd, run /mcp and authenticate: linear, notion, figma
     (OAuth is per-person by design — once per server.)

Notes: the first run in any repo asks for folder trust once. WebSearch and
/logout don't exist on Bedrock; auth is AWS-side (re-run `aws login`).
EOF
