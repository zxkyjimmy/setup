#!/bin/bash

FONT_VERSION="3.4.0"
FONT_NAME="CascadiaCode"
mkdir -p ~/.local/share/fonts
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v${FONT_VERSION}/${FONT_NAME}.zip
mkdir -p ${FONT_NAME}
unzip ${FONT_NAME}.zip -d ${FONT_NAME}
find -type f -name '*Windows*' -delete
cp -r ${FONT_NAME} ~/.local/share/fonts
fc-cache -f -v

# Set terminal font to CaskaydiaCove Nerd Font 14
. /etc/os-release
if dpkg --compare-versions "$VERSION_ID" ge "25.10"; then
    gsettings set org.gnome.Ptyxis use-system-font false
    gsettings set org.gnome.Ptyxis font-name "CaskaydiaCove Nerd Font 14"
    gsettings set org.gnome.Ptyxis restore-window-size false
    gsettings set org.gnome.Ptyxis window-size "(uint32 80, uint32 24)"
else
    PROFILE_ID=$( gsettings get org.gnome.Terminal.ProfilesList default | xargs echo )
    dconf write /org/gnome/terminal/legacy/profiles:/:${PROFILE_ID}/use-system-font false
    dconf write /org/gnome/terminal/legacy/profiles:/:${PROFILE_ID}/font "'CaskaydiaCove Nerd Font 14'"
fi
