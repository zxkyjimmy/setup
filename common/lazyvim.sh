#!/usr/bin/env bash

set -euo pipefail

NVIM_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"

# Remove existing Neovim configuration
rm -rf ~/.config/nvim
rm -rf ~/.local/share/nvim
rm -rf ~/.local/state/nvim
rm -rf ~/.cache/nvim

# Install LazyVim
git clone https://github.com/LazyVim/starter ~/.config/nvim
rm -rf ~/.config/nvim/.git

# Enable LazyVim extras
cat >"$NVIM_CONFIG/lazyvim.json" <<'EOF'
{
  "extras": [
    "lazyvim.plugins.extras.lang.json",
    "lazyvim.plugins.extras.lang.python",
    "lazyvim.plugins.extras.lang.toml"
  ],
  "install_version": 8,
  "version": 8
}
EOF

# Configure Python LSP
echo 'vim.g.lazyvim_python_lsp = "basedpyright"' |
  tee -a "$NVIM_CONFIG/lua/config/options.lua"

# Configure transparent background
tee "$NVIM_CONFIG/lua/plugins/colorscheme.lua" >/dev/null <<'EOF'
return {
  {
    "folke/tokyonight.nvim",
    opts = {
      transparent = true,
      styles = {
        sidebars = "transparent",
        floats = "transparent",
      },
    },
  },
}
EOF
