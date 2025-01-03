#!/bin/zsh

set -euo pipefail

ztarget='$HOME/.zsh'
export ZDOTDIR=$(eval echo $ztarget)

function step(){
  echo "$(tput setaf 10)$1$(tput sgr0)"
}

function info(){
  echo "$(tput setaf 14)$1$(tput sgr0)"
}

info "Running macos script"

step "Create \$ZDOTDIR"
[ -d $ZDOTDIR ] || mkdir -p $ZDOTDIR
cat << EOF | tee -a $HOME/.zshenv
export ZDOTDIR="$ztarget"
EOF
ln -sf $HOME/.zshenv $ZDOTDIR

step "HomeBrew"
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
if [[ $(uname -p) == 'arm' ]]; then
  step "Set Apple Silicon HomeBrew Path"
  echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' | tee -a ${ZDOTDIR:-$HOME}/.zprofile
  echo 'FPATH="$(brew --prefix)/share/zsh/site-functions:${FPATH}"' | tee -a ${ZDOTDIR:-$HOME}/.zprofile
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

step "Install chezmoi"
brew install chezmoi
chezmoi init zxkyjimmy --apply --force

step "Install utils"
brew install htop tree openssh cmake gh julia tmux neovim
brew install --cask google-chrome arc
brew install --cask visual-studio-code
brew install --cask hyper
brew install --cask mos the-unarchiver
brew install --cask topnotch # hide the notch
brew install --cask slack telegram discord notion webex
brew install --cask zen-browser

step "SSH"
[ -d ~/.ssh ] || mkdir ~/.ssh
ssh-keygen -b 4096 -t rsa -f ~/.ssh/id_rsa -q -N "" <<< y
echo "" # newline

step "Font"
# brew tap homebrew/cask-fonts
brew install --cask font-sauce-code-pro-nerd-font
brew install --cask font-caskaydia-cove-nerd-font

step "Get Oh my tmux"
cd $HOME
git clone https://github.com/gpakosz/.tmux.git
ln -s -f .tmux/.tmux.conf
cd -

step "Python"
brew install python

step "Miniconda 3"
brew install --cask miniconda
# conda init "$(basename "${SHELL}")"
# conda config --set auto_activate_base false

step "Podman"
brew install podman
podman machine init

step "Node Version Manager"
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
. $HOME/.nvm/nvm.sh
nvm install node
