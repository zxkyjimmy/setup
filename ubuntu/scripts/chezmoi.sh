#!/usr/bin/env bash
set -euo pipefail

export PATH=$HOME/.local/bin:$PATH
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b $HOME/.local/bin
chezmoi init zxkyjimmy --apply --force
case $USER in
  jimmy | zxkyjimmy)
    echo "keep chezmoi"
    ;;
  *)
    echo "remove chezmoi directory"
    rm -rf $HOME/.local/share/chezmoi
    git config --global --unset user.name
    git config --global --unset user.email
    ;;
esac
