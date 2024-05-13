#!/bin/bash

case `uname` in
  Darwin)
    macos/install.sh
  ;;
  Linux)
    ubuntu/install.sh
  ;;
esac
