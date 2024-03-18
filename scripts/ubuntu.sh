#!/usr/bin/bash
set -euo pipefail

function step(){
  echo "$(tput setaf 10)$1$(tput sgr0)"
}

Port="${1:-22}"

step "Set locale"
sudo locale-gen en_US.UTF-8
sudo locale-gen zh_TW.UTF-8
export LC_ALL=en_US.UTF-8

step "Update all packages"
sudo apt update
sudo apt upgrade -y
sudo apt autoremove -y

step "Stop unattended upgrade"
sudo sed -E 's;APT::Periodic::Unattended-Upgrade "1"\;;APT::Periodic::Unattended-Upgrade "0"\;;g' -i /etc/apt/apt.conf.d/20auto-upgrades

step "Get useful commands"
sudo apt update
sudo apt install -y gh curl zsh wget htop vim tree openssh-server lm-sensors \
                    cmake tmux python3-pip python-is-python3 clang clang-tools

step "Set ssh port&key"
sudo sed -E 's;#?(Port ).*;\1'"$Port"';g' -i /etc/ssh/sshd_config
sudo service ssh restart
[ -d ~/.ssh ] || mkdir ~/.ssh
ssh-keygen -b 4096 -t rsa -f ~/.ssh/id_rsa -q -N "" <<< y
echo "" # newline

step "Get Font"
FONT_VERSION="3.1.1"
FONT_NAME="CascadiaCode"
mkdir -p ~/.local/share/fonts
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v${FONT_VERSION}/${FONT_NAME}.zip
mkdir -p ${FONT_NAME}
unzip ${FONT_NAME}.zip -d ${FONT_NAME}
find -type f -name '*Windows*' -delete
cp -r ${FONT_NAME} ~/.local/share/fonts
fc-cache -f -v

step "Tweak theme and terminal"
PROFILE_ID=$( gsettings get org.gnome.Terminal.ProfilesList default | xargs echo )
dconf write /org/gnome/terminal/legacy/profiles:/:${PROFILE_ID}/use-system-font false
dconf write /org/gnome/terminal/legacy/profiles:/:${PROFILE_ID}/font "'CaskaydiaCove Nerd Font 14'"

step "Install Gnu stow"
sudo apt update
sudo apt install -y stow
git clone https://github.com/zxkyjimmy/dotfiles ~/.dotfiles
stow -d ~/.dotfiles --adopt git zsh tmux conda
[ -d ${HOME}/.config/yapf ] || mkdir -p ${HOME}/.config/yapf
stow -d ~/.dotfiles -t ~/.config/yapf --adopt yapf
git -C ~/.dotfiles checkout -- .

step "Get oh-my-zsh"
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)" "" --unattended --keep-zshrc
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
git clone https://github.com/zsh-users/zsh-autosuggestions.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
git clone https://github.com/esc/conda-zsh-completion ${ZSH_CUSTOM:=~/.oh-my-zsh/custom}/plugins/conda-zsh-completion

step "Get Oh my tmux"
git clone https://github.com/gpakosz/.tmux.git ${HOME}/.tmux
ln -s -f ${HOME}/.tmux/.tmux.conf ${HOME}

step "Change default shell"
sudo chsh -s /usr/bin/zsh ${USER}

step "Set Time Zone"
sudo timedatectl set-timezone Asia/Taipei

step "Get Miniconda3"
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O miniconda.sh
bash miniconda.sh -b -u -p $HOME/miniconda
eval "$(${HOME}/miniconda/bin/conda shell.bash hook)"
# conda init zsh
# conda config --set auto_activate_base false

step "Get CUDA"
wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-keyring_1.1-1_all.deb
sudo dpkg -i cuda-keyring_1.1-1_all.deb
sudo apt update
sudo apt install -y cuda-toolkit-12-4 cuda-drivers
sudo apt install -y cudnn
sudo sed -E 's;PATH="?(.+)";PATH="/usr/local/cuda/bin:\1";g' -i /etc/environment

step "Install Bazel"
sudo apt install -y apt-transport-https curl gnupg
curl -fsSL https://bazel.build/bazel-release.pub.gpg | gpg --dearmor > bazel-archive-keyring.gpg
sudo mv bazel-archive-keyring.gpg /usr/share/keyrings
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/bazel-archive-keyring.gpg] https://storage.googleapis.com/bazel-apt stable jdk1.8" | sudo tee /etc/apt/sources.list.d/bazel.list
sudo apt update
sudo apt install -y bazel

step "Install Podman"
sudo apt update
sudo apt upgrade -y
sudo apt install -y podman
sudo sed -E 's;# unqualified-search-registries = \["example.com"\];unqualified-search-registries = \["docker.io"\];1' -i /etc/containers/registries.conf

step "Install nvidia-container-toolkit"
sudo apt update
sudo apt install -y nvidia-container-toolkit
# No runtime/config.toml since nvidia-container-toolkit v1.14.1
# Don't convert to cdi untill podman v4.1.0
# sudo nvidia-ctk config default --output=/etc/nvidia-container-runtime/config.toml
sudo sed -i 's/^#no-cgroups = false/no-cgroups = true/;' /etc/nvidia-container-runtime/config.toml
sudo mkdir -p /usr/share/containers/oci/hooks.d
cat <<EOF | sudo tee /usr/share/containers/oci/hooks.d/oci-nvidia-hook.json
{
    "version": "1.0.0",
    "hook": {
        "path": "/usr/bin/nvidia-container-toolkit",
        "args": ["nvidia-container-toolkit", "prestart"],
        "env": [
            "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
        ]
    },
    "when": {
        "always": true,
        "commands": [".*"]
    },
    "stages": ["prestart"]
}
EOF

step "Node Version Manager"
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
. $HOME/.nvm/nvm.sh
nvm install node

step "stop cups-browsed"
sudo systemctl stop cups-browsed.service
sudo systemctl disable cups-browsed.service

step "clean up"
sudo apt update
sudo apt upgrade -y
sudo apt autoremove -y
sudo apt autoclean

ip=$(curl https://ipinfo.io/ip)
echo $ip
if [ ${ip:0:7} == "140.109" ]; then
    step "Install xensor.sh"
    curl https://myspace.sinica.edu.tw/public.php\?service\=files\&t\=pGthCoK2eMwJYPt7Ku10REZlwbLk12szeJiw2QSmwsKsIRxMo-KsjqhlH2Ppg5Jm -o xensor.sh
    sudo bash xensor.sh -f
else
    echo "No in Sinica"
fi
