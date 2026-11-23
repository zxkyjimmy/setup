#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"
source ../lib/steps.sh

ztarget='$HOME/.zsh'
export ZDOTDIR=$(eval echo $ztarget)

info "Create \$ZDOTDIR"
[ -d $ZDOTDIR ] || mkdir -p $ZDOTDIR
cat << EOF | tee -a $HOME/.zshenv
export ZDOTDIR="$ztarget"
skip_global_compinit=1
EOF
ln -sf $HOME/.zshenv $ZDOTDIR

info "Set locale"
sudo locale-gen en_US.UTF-8
sudo locale-gen zh_TW.UTF-8
export LC_ALL=en_US.UTF-8

run_step "APT packages" scripts/apt.sh
run_step "Change default shell" sudo chsh -s /usr/bin/zsh ${USER}
run_step "Install chezmoi" scripts/chezmoi.sh
run_step "ssh key generate" scripts/ssh.sh
run_step "Set Time Zone" sudo timedatectl set-timezone Asia/Taipei
if [ "$XDG_CURRENT_DESKTOP" = "ubuntu:GNOME" ]; then
  run_step "Install Nerd Fonts" scripts/font.sh
fi
run_step "Install Miniconda3" scripts/conda.sh

gpu=$(lspci | grep -i '.* vga .* nvidia .*' || echo "")
shopt -s nocasematch
if [[ $gpu == *' nvidia '* ]]; then
  run_step "Install CUDA and nvidia-container-toolkit" \
    scripts/cuda.sh
fi
shopt -u nocasematch

run_step "Install uv" scripts/uv.sh
run_step "Install rustup" scripts/rustup.sh
run_step "Install Ghostty" scripts/ghostty.sh
run_step "Install VS Code" scripts/vscode.sh
run_step "Install Oh my tmux" scripts/tmux.sh
run_step "Install herdr" scripts/herdr.sh
run_step "Install neovim" scripts/neovim.sh
run_step "Install LazyVim" git clone https://github.com/LazyVim/starter ~/.config/nvim
run_step "Install yazi" scripts/yazi.sh
run_step "Install Claude Code" scripts/claude.sh
run_step "Install Codex" scripts/codex.sh
run_step "Install Antigravity" scripts/antigravity.sh
# run_step "Install eza" scripts/eza.sh

ip=$(curl https://ipinfo.io/ip)
echo $ip
if [ ${ip:0:11} == "140.109.135" ]; then
  # curl https://myspace.sinica.edu.tw/public.php\?service\=files\&t\=9ZJ7YsQvGLRIFeRwcBDC9SjmzQYpIqMbH1otGg8e50kw2Y6Wbp3F5wx6sv1-A3xB -o xensor.sh
  run_step "Install xensor" sudo bash scripts/xensor.sh -f
fi

info "stop cups-browsed"
sudo systemctl stop cups-browsed.service
sudo systemctl disable cups-browsed.service

info "clean up"
sudo apt update
sudo apt upgrade -y
sudo apt autoremove --purge -y
sudo apt autoclean

printf '\n🎉 Ubuntu setup completed!\n'
