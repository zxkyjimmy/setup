#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

platform="$(uname -s)"

if [[ "$platform" == "Linux" ]]; then
  if [[ ! -r /etc/os-release ]]; then
    echo "Cannot determine Linux distribution." >&2
    exit 1
  fi

  . /etc/os-release
  platform="$ID"

  if [[ -n "${WSL_DISTRO_NAME:-}" ]] ||
    grep -Eqi '(microsoft|wsl)' /proc/sys/kernel/osrelease; then
    platform="wsl"
  fi
fi

case "$platform" in
  Darwin)
    macos/install.sh
    ;;
  ubuntu)
    ubuntu/install.sh
    ;;
  *)
    echo "Unsupported platform: $platform" >&2
    exit 1
    ;;
esac
