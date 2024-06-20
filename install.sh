#!/bin/bash

if [[ -f /proc/sys/fs/binfmt_misc/WSLInterop ]]; then
  wsl/install.sh
  exit 0
fi

case `uname` in
  Darwin)
    macos/install.sh
  ;;
  Linux)
    ubuntu/install.sh
  ;;
esac
