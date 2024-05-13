#!/bin/bash

FONT_VERSION="3.2.1"
FONT_NAME="CascadiaCode"
mkdir -p ~/.local/share/fonts
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v${FONT_VERSION}/${FONT_NAME}.zip
mkdir -p ${FONT_NAME}
unzip ${FONT_NAME}.zip -d ${FONT_NAME}
find -type f -name '*Windows*' -delete
cp -r ${FONT_NAME} ~/.local/share/fonts
fc-cache -f -v

PROFILE_ID=$( gsettings get org.gnome.Terminal.ProfilesList default | xargs echo )
dconf write /org/gnome/terminal/legacy/profiles:/:${PROFILE_ID}/use-system-font false
dconf write /org/gnome/terminal/legacy/profiles:/:${PROFILE_ID}/font "'CaskaydiaCove Nerd Font 14'"
