#!/usr/bin/env bash
set -euo pipefail

cd $HOME
git clone https://github.com/gpakosz/.tmux.git
ln -s -f .tmux/.tmux.conf
cd -
