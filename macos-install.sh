#!/bin/zsh
set -euo pipefail

function step(){
  echo "$(tput setaf 10)$1$(tput sgr0)"
}

step "HomeBrew"
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
if [[ $(uname -p) == 'arm' ]]; then
  step "Set Apple Silicon HomeBrew Path"
  echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ${HOME}/.zprofile
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

step "Git"
git config --global user.name "Yen-Chi Chen"
git config --global user.email "zxkyjimmy@gmail.com"
git config --global pull.rebase false
cp git/.gitignore ${HOME}/
git config --global core.excludesFile "~/.gitignore"

step "Install utils"
brew install htop tree openssh cmake gh julia
brew install --cask the-unarchiver oracle-jdk mos
brew install --cask topnotch # hide the notch

step "SSH"
[ -d ~/.ssh ] || mkdir ~/.ssh
ssh-keygen -b 4096 -t rsa -f ~/.ssh/id_rsa -q -N "" <<< y
echo "" # newline

step "Font"
brew tap homebrew/cask-fonts
brew install font-sauce-code-pro-nerd-font
brew install font-caskaydia-cove-nerd-font

step "Powerlevel10k"
zsh/install.sh

step "Homebrew's completions"
cat << EOF >> ~/.zshrc
# Homebrew's completions
if type brew &>/dev/null
then
  FPATH="\$(brew --prefix)/share/zsh/site-functions:\${FPATH}"
  autoload -Uz compinit
  compinit
fi
EOF

step "Python"
brew install python
echo "\n# Python path" >> ~/.zshrc
echo "export PATH=\$PATH:\$(brew --prefix python)/bin" >> ~/.zshrc
echo "export PATH=\$PATH:\$(brew --prefix python)/libexec/bin" >> ~/.zshrc

step "HyperTerminal"
brew install --cask hyper
cp hyper/.hyper.js ${HOME}/

step "Miniconda 3"
brew install --cask miniconda
conda init "$(basename "${SHELL}")"
conda config --set auto_activate_base false

step "Node Version Manager"
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash
. $HOME/.nvm/nvm.sh
nvm install node
