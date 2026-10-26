#!/bin/bash

FONT_VERSION="3.5.1"
FONT_NAMES=(
    "CascadiaCode"
    "SourceCodePro"
    "Monaspace"
    "Meslo"
    "AnnotationMono"
)

# Terminal font (only one)
TERMINAL_FONT="CaskaydiaCove Nerd Font 14"

# Directories
FONT_DIR="${HOME}/.local/share/fonts"

mkdir -p "$FONT_DIR"

# Install all fonts
for FONT_NAME in "${FONT_NAMES[@]}"; do
    echo "Installing ${FONT_NAME} Nerd Font..."
    wget https://github.com/ryanoasis/nerd-fonts/releases/download/v${FONT_VERSION}/${FONT_NAME}.zip
    mkdir -p ${FONT_NAME}
    unzip ${FONT_NAME}.zip -d ${FONT_NAME}
    find -type f -name '*Windows*' -delete
    cp -r ${FONT_NAME} ${FONT_DIR}
done
fc-cache -f -v

# Set terminal font
. /etc/os-release
if dpkg --compare-versions "$VERSION_ID" ge "25.10"; then
    gsettings set org.gnome.Ptyxis use-system-font false
    gsettings set org.gnome.Ptyxis font-name "$TERMINAL_FONT"
    gsettings set org.gnome.Ptyxis restore-window-size false
    gsettings set org.gnome.Ptyxis window-size "(uint32 80, uint32 24)"
else
    PROFILE_ID=$( gsettings get org.gnome.Terminal.ProfilesList default | xargs echo )
    dconf write /org/gnome/terminal/legacy/profiles:/:${PROFILE_ID}/use-system-font false
    dconf write /org/gnome/terminal/legacy/profiles:/:${PROFILE_ID}/font "'${TERMINAL_FONT}'"
fi

echo "All fonts installed successfully!"
echo "Terminal font: ${TERMINAL_FONT}"
