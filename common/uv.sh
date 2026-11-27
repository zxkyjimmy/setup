#!/usr/bin/env bash
set -euo pipefail

curl -LsSf https://astral.sh/uv/install.sh | env UV_NO_MODIFY_PATH=1 sh

export PATH="$HOME/.local/bin:$PATH"
uv tool install pre-commit
