#!/usr/bin/env bash

export PATH=$HOME/.local/bin:$PATH
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b $HOME/.local/bin
chezmoi init zxkyjimmy --apply --force
case $USER in
  jimmy | zxkyjimmy)
    info "keep chezmoi"
    ;;
  *)
    info "remove chezmoi directory"
    rm -rf $HOME/.local/share/chezmoi
    git config --global --unset user.name
    git config --global --unset user.email
    ;;
esac
