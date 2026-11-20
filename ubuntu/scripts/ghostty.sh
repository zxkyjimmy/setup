#!/usr/bin/env bash

/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/mkasberg/ghostty-ubuntu/HEAD/install.sh)"
mkdir -p "$HOME/.config"
echo "com.mitchellh.ghostty.desktop" > "$HOME/.config/ubuntu-xdg-terminals.list"
