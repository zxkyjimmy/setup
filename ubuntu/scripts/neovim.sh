#!/usr/bin/env bash

sudo apt install -y software-properties-common
sudo add-apt-repository -y ppa:neovim-ppa/stable
sudo apt update
sudo apt install -y neovim
