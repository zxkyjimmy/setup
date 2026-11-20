#!/usr/bin/env bash

step=0

# Colors
BLUE='\033[1;36m'
GREEN='\033[1;32m'
RED='\033[1;31m'
RESET='\033[0m'

function run_step() {
  local name="$1"
  shift

  step=$((step + 1))

  printf "\n${BLUE}📦 [%d] %s...${RESET}\n" \
    "$step" "$name"

  if "$@"; then
    printf "${GREEN}✓ Completed: %s${RESET}\n" "$name"
  else
    local status=$?
    printf "${RED}✗ Failed: %s (exit %d)${RESET}\n" \
      "$name" "$status" >&2
    return "$status"
  fi
}

function info() {
  echo "📝 $(tput setaf 14)$1$(tput sgr0)"
}
