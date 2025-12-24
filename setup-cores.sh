#!/usr/bin/env bash
# Edit CORE_REPOS below to add/remove cores


RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color


PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"




if [ -z "${SETUP_CORES_CONFIG_LOADED:-}" ]; then
  SETUP_CORES_CONFIG_LOADED=1

  CORE_REPOS=(
    "fceumm=https://github.com/rebitplay/libretro-fceumm.git"
    "snes9x=https://github.com/rebitplay/snes9x.git"
    "mgba=https://github.com/rebitplay/mgba.git"
    "pcsx_rearmed=https://github.com/rebitplay/pcsx_rearmed.git"
    "melonds=https://github.com/rebitplay/melonDS.git"
    "sameboy=https://github.com/rebitplay/SameBoy.git"
  )


  AVAILABLE_CORES=()
  for kv in "${CORE_REPOS[@]}"; do
    AVAILABLE_CORES+=("${kv%%=*}")
  done


  get_core_repo() {
    local core="$1"
    local kv name url
    if [ -z "$core" ]; then
      return 1
    fi
    for kv in "${CORE_REPOS[@]}"; do
      name="${kv%%=*}"
      url="${kv#*=}"
      if [ "$name" = "$core" ]; then
        printf '%s\n' "$url"
        return 0
      fi
    done
    return 1
  }


  list_core_repos() {
    local kv name url
    if [ "${#AVAILABLE_CORES[@]}" -eq 0 ]; then
      printf "No cores configured in CORE_REPOS\n"
      return 0
    fi
    printf 'Available cores (%d):\n\n' "${#AVAILABLE_CORES[@]}"
    for kv in "${CORE_REPOS[@]}"; do
      name="${kv%%=*}"
      url="${kv#*=}"
      printf '  - %-12s -> %s\n' "${name}" "${url}"
    done
  }


  is_core_known() {
    get_core_repo "$1" >/dev/null 2>&1
    return $?
  }
fi



print_usage() {
  echo -e "${BLUE}Usage:${NC}"
  echo -e "  $0                  # clone all cores"
  echo -e "  $0 <core> [others]  # clone specific cores"
  echo -e "  $0 list             # show available cores & repository URLs"
  echo -e ""
  echo -e "${BLUE}Available cores:${NC}"
  for core in "${AVAILABLE_CORES[@]}"; do
    echo -e "  - $core"
  done
  echo ""
  echo -e "${BLUE}Examples:${NC}"
  echo -e "  $0 fceumm"
  echo -e "  $0 fceumm snes9x"
  echo -e "  $0 all"
}


clone_core() {
  local CORE_NAME="$1"
  local REPO_URL


  REPO_URL=$(get_core_repo "$CORE_NAME" 2>/dev/null || true)

  if [ -z "$REPO_URL" ]; then
    echo -e "${RED}Error: Unknown core '$CORE_NAME'${NC}"
    echo -e "Available cores: ${AVAILABLE_CORES[*]}"
    return 1
  fi

  local CORES_DIR="$PROJECT_ROOT/cores"
  local TARGET_DIR="$CORES_DIR/libretro-$CORE_NAME"

  # Create cores directory if it doesn't exist
  mkdir -p "$CORES_DIR"

  if [ -d "$TARGET_DIR" ]; then
    echo -e "${YELLOW}Directory $TARGET_DIR already exists, skipping...${NC}"
    return 0
  fi

  echo -e "${BLUE}Cloning $CORE_NAME from $REPO_URL...${NC}"
  git clone --depth=1 --recursive "$REPO_URL" "$TARGET_DIR"
  echo -e "${GREEN}✓ $CORE_NAME cloned successfully${NC}"
  return 0
}


check_git() {
  if ! command -v git >/dev/null 2>&1; then
    echo -e "${RED}Error: git not found. Please install git to clone repositories.${NC}"
    return 1
  fi
  return 0
}


main_setup() {
  # Fail fast for the main flow only
  set -e


  echo -e "${GREEN}=== Setup Libretro Cores ===${NC}\n"


  check_git || exit 1

  if [ $# -eq 0 ]; then
    echo -e "${BLUE}Cloning all configured core repositories...${NC}\n"
    for core in "${AVAILABLE_CORES[@]}"; do
      clone_core "$core" || true
    done
  else
    if [ "$1" = "list" ]; then
      list_core_repos
      return 0
    fi

    if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
      print_usage
      return 0
    fi

    echo -e "${BLUE}Cloning specified cores: $@${NC}\n"
    for core in "$@"; do
      if ! is_core_known "$core"; then
        echo -e "${RED}Error: Unknown core '$core'${NC}"
        echo -e "Available cores: ${AVAILABLE_CORES[*]}"
        exit 1
      fi
      clone_core "$core"
    done
  fi

  echo -e "\n${GREEN}=== Setup Complete! ===${NC}"
  echo -e "${YELLOW}You can now run: ./build-cores.sh <core_name>${NC}"
}


if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  # Pass all arguments through to main_setup
  main_setup "$@"
fi
