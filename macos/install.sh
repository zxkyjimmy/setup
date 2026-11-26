#!/usr/bin/env zsh
set -euo pipefail

cd "$(dirname "$0")"
source ../lib/steps.sh

ztarget='$HOME/.zsh'
export ZDOTDIR=$(eval echo $ztarget)

info "Create \$ZDOTDIR"
[ -d $ZDOTDIR ] || mkdir -p $ZDOTDIR
cat << EOF | tee -a $HOME/.zshenv
export ZDOTDIR="$ztarget"
# Ensure unique PATH entries
typeset -U PATH path
EOF
ln -sf $HOME/.zshenv $ZDOTDIR

info "Install HomeBrew"
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
if [[ $(uname -p) == 'arm' ]]; then
  info "Set Apple Silicon HomeBrew Path"
  echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' | tee -a ${ZDOTDIR:-$HOME}/.zprofile
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

run_step "Homebrew packages" \
  brew bundle install --no-upgrade --file=Brewfile --verbose
run_step "Chezmoi initialize" chezmoi init zxkyjimmy --apply --force
run_step "ssh key generate" scripts/ssh.sh
run_step "Install Oh my tmux" scripts/tmux.sh
run_step "Install uv" scripts/uv.sh
run_step "Install LazyVim" git clone https://github.com/LazyVim/starter ~/.config/nvim

printf '\n🎉 macOS setup completed!\n'
