#!/usr/bin/env bash

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

# Install packages
sudo apt update
if (( ${#packages[@]} > 0 )); then
  sudo apt install -y "${packages[@]}"
fi
