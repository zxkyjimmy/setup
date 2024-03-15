#!/usr/bin/env bash

case `uname` in
  Darwin)
    echo "Running macos script"
    scripts/macos.sh
  ;;
  Linux)
    echo "Running ubuntu script"
    scripts/ubuntu.sh
  ;;
esac
