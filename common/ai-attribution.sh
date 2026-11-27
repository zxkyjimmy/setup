#!/usr/bin/env bash

set -euo pipefail

CLAUDE_CONFIG="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/settings.json"
CODEX_DIR="${CODEX_HOME:-$HOME/.codex}"
CODEX_AGENTS="$CODEX_DIR/AGENTS.md"

# Disable Claude Code attribution
mkdir -p "$(dirname "$CLAUDE_CONFIG")"
[[ -f "$CLAUDE_CONFIG" ]] || echo '{}' > "$CLAUDE_CONFIG"

tmp=$(mktemp "${CLAUDE_CONFIG}.XXXXXX")
trap 'rm -f "$tmp"' EXIT

jq '.attribution = false' "$CLAUDE_CONFIG" > "$tmp"
mv "$tmp" "$CLAUDE_CONFIG"

# Disable Codex attribution via global instructions
mkdir -p "$CODEX_DIR"

if [[ -s "$CODEX_DIR/AGENTS.override.md" ]]; then
  CODEX_AGENTS="$CODEX_DIR/AGENTS.override.md"
fi

touch "$CODEX_AGENTS"

if ! grep -Fqx '## Git Attribution' "$CODEX_AGENTS"; then
  cat >> "$CODEX_AGENTS" <<'EOF'

## Git Attribution

- Do not add AI attribution to commit messages or pull requests.
- Do not include AI-related Co-authored-by trailers.
- Do not modify the Git author or committer identity.
- Respect repository-specific AI disclosure requirements.
EOF
fi
