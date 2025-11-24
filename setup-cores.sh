#!/bin/bash

# Setup script to clone libretro core repositories
# This script helps you clone the core repositories you need

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get the script directory (project root)
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Function to get core repository URL
get_core_repo() {
    local core=$1
    case $core in
        fceumm)
            echo "https://github.com/libretro/libretro-fceumm.git"
            ;;
        snes9x)
            echo "https://github.com/libretro/snes9x.git"
            ;;
        mgba)
            echo "https://github.com/libretro/mgba.git"
            ;;
        *)
            echo ""
            ;;
    esac
}

# Available cores
AVAILABLE_CORES=(fceumm snes9x mgba)

# Function to clone a core repository
clone_core() {
    local CORE_NAME=$1
    local REPO_URL=$(get_core_repo "$CORE_NAME")

    if [ -z "$REPO_URL" ]; then
        echo -e "${RED}Error: Unknown core '$CORE_NAME'${NC}"
        echo -e "Available cores: ${AVAILABLE_CORES[*]}"
        return 1
    fi

    local TARGET_DIR="$PROJECT_ROOT/libretro-$CORE_NAME"

    if [ -d "$TARGET_DIR" ]; then
        echo -e "${YELLOW}Directory $TARGET_DIR already exists, skipping...${NC}"
        return 0
    fi

    echo -e "${BLUE}Cloning $CORE_NAME from $REPO_URL...${NC}"
    git clone --depth=1 "$REPO_URL" "$TARGET_DIR"
    echo -e "${GREEN}✓ $CORE_NAME cloned successfully${NC}"
}

# Main
echo -e "${GREEN}=== Setup Libretro Cores ===${NC}\n"

if [ $# -eq 0 ]; then
    echo -e "${BLUE}Cloning all core repositories...${NC}\n"
    for core in "${AVAILABLE_CORES[@]}"; do
        clone_core "$core"
    done
else
    echo -e "${BLUE}Cloning specified cores: $@${NC}\n"
    for core in "$@"; do
        local repo_url=$(get_core_repo "$core")
        if [ -z "$repo_url" ]; then
            echo -e "${RED}Error: Unknown core '$core'${NC}"
            echo -e "Available cores: ${AVAILABLE_CORES[*]}"
            exit 1
        fi
        clone_core "$core"
    done
fi

echo -e "\n${GREEN}=== Setup Complete! ===${NC}"
echo -e "${YELLOW}You can now run: ./build-cores.sh <core_name>${NC}"
