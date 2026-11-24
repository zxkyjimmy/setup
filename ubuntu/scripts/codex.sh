#!/usr/bin/env bash
set -euo pipefail

# Set the PATH to prevent the modification to .bashrc/.zshrc
curl -fsSL https://chatgpt.com/codex/install.sh \
    | PATH="$HOME/.local/bin:$PATH" \
      CODEX_NON_INTERACTIVE=1 sh
