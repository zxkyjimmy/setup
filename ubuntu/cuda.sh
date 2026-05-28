#!/bin/bash
wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2604/x86_64/cuda-keyring_1.1-1_all.deb
sudo dpkg -i cuda-keyring_1.1-1_all.deb
sudo apt update
sudo apt install -y cuda-drivers

sudo apt install -y nvidia-container-toolkit
sudo sed -i 's/^#no-cgroups = false/no-cgroups = true/;' /etc/nvidia-container-runtime/config.toml
sudo sed -i.bak -E 's/(GRUB_CMDLINE_LINUX_DEFAULT="[^"]*)\bsplash\b ?/\1/' /etc/default/grub
sudo update-grub
