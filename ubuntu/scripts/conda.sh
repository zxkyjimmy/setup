#!/usr/bin/env bash
set -euo pipefail

wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O miniconda.sh
bash miniconda.sh -b -u -p $HOME/.miniconda
