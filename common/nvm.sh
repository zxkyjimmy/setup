#!/usr/bin/env bash
set -euo pipefail

export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"

if [[ ! -f "$NVM_DIR/nvm.sh" ]]; then
  echo "Installing nvm..."

  git clone https://github.com/nvm-sh/nvm.git "$NVM_DIR"

  cd "$NVM_DIR"
  version="$(git describe --abbrev=0 --tags --match "v[0-9]*" \
    "$(git rev-list --tags --max-count=1)")"
  git checkout --quiet "$version"
else
  echo "nvm is already installed."
fi

# nvm may not work correctly with strict shell options.
set +eu
set +o pipefail

source "$NVM_DIR/nvm.sh" --no-use || exit 1

if ! nvm version default >/dev/null 2>&1; then
  echo "Installing Node.js..."

  nvm install node || exit 1
  nvm alias default node || exit 1
else
  echo "Node.js is already configured."
fi
