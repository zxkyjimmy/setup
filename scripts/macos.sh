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

step "Install utils"
brew install htop tree openssh cmake gh julia tmux neovim
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

# step "Terminal Font"
# osascript <<'END'
# tell application "Terminal"
#     set ProfilesNames to name of every settings set
#     repeat with ProfileName in ProfilesNames
#         set font name of settings set ProfileName to "CaskaydiaCove Nerd Font"
#         set font size of settings set ProfileName to 16
#     end repeat
# end tell
# END

step "Install GNU stow"
brew install stow
git clone https://github.com/zxkyjimmy/dotfiles ~/.dotfiles
stow -d ~/.dotfiles --adopt git zsh tmux conda hyper
[ -d ${HOME}/.config/yapf ] || mkdir -p ${HOME}/.config/yapf
stow -d ~/.dotfiles -t ~/.config/yapf --adopt yapf
git -C ~/.dotfiles checkout -- .

step "Oh My Zsh + Powerlevel10k"
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)" "" --unattended --keep-zshrc
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
git clone https://github.com/zsh-users/zsh-autosuggestions.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
git clone https://github.com/esc/conda-zsh-completion ${ZSH_CUSTOM:=~/.oh-my-zsh/custom}/plugins/conda-zsh-completion

step "Get Oh my tmux"
git clone https://github.com/gpakosz/.tmux.git ${HOME}/.tmux
ln -s -f ${HOME}/.tmux/.tmux.conf ${HOME}

step "Python"
brew install python

step "HyperTerminal"
brew install --cask hyper

step "Miniconda 3"
brew install --cask miniconda
# conda init "$(basename "${SHELL}")"
# conda config --set auto_activate_base false

step "Podman"
brew install podman
podman machine init

step "Node Version Manager"
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
. $HOME/.nvm/nvm.sh
nvm install node
