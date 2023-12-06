#!/bin/zsh
# set -euo pipefail

SCRIPT=$(readlink -f $0)
SCRIPTPATH=$(dirname $SCRIPT)
cd $SCRIPTPATH

# Clone
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)" "" --unattended
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
git clone https://github.com/zsh-users/zsh-autosuggestions.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
git clone https://github.com/esc/conda-zsh-completion ${ZSH_CUSTOM:=~/.oh-my-zsh/custom}/plugins/conda-zsh-completion
cp .p10k.zsh ${HOME}/.p10k.zsh

# Prefix
cat << EOF | cat - ~/.zshrc >> temp && mv temp ~/.zshrc
# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "\${XDG_CACHE_HOME:-\$HOME/.cache}/p10k-instant-prompt-\${(%):-%n}.zsh" ]]; then
  source "\${XDG_CACHE_HOME:-\$HOME/.cache}/p10k-instant-prompt-\${(%):-%n}.zsh"
fi

zstyle ':omz:update' mode disabled
ZLE_RPROMPT_INDENT=0

EOF

# Suffix
cat << EOF >> ~/.zshrc

# To customize prompt, run \`p10k configure\` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

EOF

source ~/.zshrc
omz theme set powerlevel10k/powerlevel10k
omz plugin enable gh zsh-autosuggestions zsh-syntax-highlighting conda-zsh-completion
