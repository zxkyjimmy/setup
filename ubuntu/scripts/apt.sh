#!/usr/bin/env bash
set -euo pipefail

file="apt-packages.txt"
mapfile -t packages < <(
  sed -e 's/#.*$//' \
    -e 's/^[[:space:]]*//' \
    -e 's/[[:space:]]*$//' \
    -e '/^$/d' \
    "$file"
)

# Stop unattended upgrade
echo 'APT::Periodic::Unattended-Upgrade "0";' |
  sudo tee /etc/apt/apt.conf.d/99-disable-unattended-upgrades

# Stop Ubuntu Pro news
echo '#clear binary::apt::AptCli::Hooks::Upgrade;' |
  sudo tee /etc/apt/apt.conf.d/21disable-esm-hook

# Add the latest git for config-based hooks
if ! command -v add-apt-repository &>/dev/null; then
  sudo apt update
  sudo apt install -y software-properties-common
fi
sudo add-apt-repository -y -n ppa:git-core/ppa

# Install packages
sudo apt update
if (( ${#packages[@]} > 0 )); then
  sudo apt install -y "${packages[@]}"
fi
