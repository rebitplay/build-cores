#!/bin/bash

# Build script for RetroArch cores for Emscripten
# This script builds one or more libretro cores and RetroArch web player
# Usage: ./build-cores.sh [core1] [core2] ... or ./build-cores.sh all
# Example: ./build-cores.sh fceumm snes9x mgba

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get the script directory (project root)
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RETROARCH_DIR="$PROJECT_ROOT/RetroArch"
WEB_DIR="$PROJECT_ROOT/web"
BUILD_OUTPUT_DIR="$PROJECT_ROOT/build"

# Available cores list
AVAILABLE_CORES=(fceumm snes9x mgba)

# Function to parse .gitlab-ci.yml for core configuration
parse_gitlab_ci() {
    local core_dir=$1
    local gitlab_file="$core_dir/.gitlab-ci.yml"

    if [ ! -f "$gitlab_file" ]; then
        echo -e "${RED}Error: .gitlab-ci.yml not found in $core_dir${NC}"
        return 1
    fi

    # Parse CORENAME, MAKEFILE_PATH (or JNI_PATH), and MAKEFILE
    local corename=$(grep -A 10 "^.core-defs:" "$gitlab_file" | grep "CORENAME:" | head -1 | awk '{print $2}' | tr -d '\r\n')
    local makefile_path=$(grep -A 10 "^.core-defs:" "$gitlab_file" | grep "MAKEFILE_PATH:" | head -1 | awk '{print $2}' | tr -d '\r\n')
    local jni_path=$(grep -A 10 "^.core-defs:" "$gitlab_file" | grep "JNI_PATH:" | head -1 | awk '{print $2}' | tr -d '\r\n')
    local makefile=$(grep -A 10 "^.core-defs:" "$gitlab_file" | grep "MAKEFILE:" | head -1 | awk '{print $2}' | tr -d '\r\n')

    # Use MAKEFILE_PATH if available, otherwise use JNI_PATH, default to "."
    local build_dir="${makefile_path:-${jni_path:-.}}"

    # Default MAKEFILE if not specified
    makefile="${makefile:-Makefile}"

    # Output format: BUILD_DIR:CORENAME:MAKEFILE
    echo "${build_dir}:${corename}:${makefile}"
}

# Function to print usage
print_usage() {
    echo -e "${BLUE}Usage:${NC}"
    echo -e "  $0 <core1> [core2] [core3] ..."
    echo -e "  $0 all"
    echo ""
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

# Function to check if emsdk is available
check_emsdk() {
    if ! command -v emcc &> /dev/null; then
        echo -e "${RED}Error: Emscripten SDK not found!${NC}"
        echo "Please install and activate emsdk first:"
        echo "  source /path/to/emsdk/emsdk_env.sh"
        exit 1
    fi
    echo -e "${YELLOW}Emscripten version:${NC}"
    emcc --version
}

# Function to build a single core
build_core() {
    local CORE_NAME=$1

    # Check if core is supported
    if [[ ! " ${AVAILABLE_CORES[@]} " =~ " ${CORE_NAME} " ]]; then
        echo -e "${RED}Error: Unknown core '${CORE_NAME}'${NC}"
        echo -e "Available cores: ${AVAILABLE_CORES[*]}"
        return 1
    fi

    local CORE_DIR="$PROJECT_ROOT/libretro-$CORE_NAME"

    echo -e "\n${GREEN}========================================${NC}"
    echo -e "${GREEN}Building ${CORE_NAME} core${NC}"
    echo -e "${GREEN}========================================${NC}"

    # Check if core directory exists
    if [ ! -d "$CORE_DIR" ]; then
        echo -e "${RED}Error: Core directory not found: $CORE_DIR${NC}"
        echo -e "${YELLOW}You may need to clone the repository first using: ./setup-cores.sh ${CORE_NAME}${NC}"
        return 1
    fi

    # Parse core configuration from .gitlab-ci.yml
    echo -e "\n${BLUE}Parsing .gitlab-ci.yml for build configuration...${NC}"
    local CORE_CONFIG=$(parse_gitlab_ci "$CORE_DIR")
    if [ -z "$CORE_CONFIG" ]; then
        echo -e "${RED}Error: Failed to parse configuration for '${CORE_NAME}'${NC}"
        return 1
    fi

    local BUILD_SUBDIR=$(echo $CORE_CONFIG | cut -d: -f1)
    local CORENAME=$(echo $CORE_CONFIG | cut -d: -f2)
    local MAKEFILE=$(echo $CORE_CONFIG | cut -d: -f3)
    local BUILD_DIR="$CORE_DIR/$BUILD_SUBDIR"
    local CORE_FILE="${CORENAME}_libretro_emscripten.bc"

    echo -e "${BLUE}  CORENAME: ${CORENAME}${NC}"
    echo -e "${BLUE}  BUILD_DIR: ${BUILD_SUBDIR}${NC}"
    echo -e "${BLUE}  MAKEFILE: ${MAKEFILE}${NC}"

    # Build the core
    # For cores with Makefile in root (e.g., mgba), run from root directory
    # For cores with Makefile in subdirectory (e.g., snes9x), run from subdirectory
    echo -e "\n${BLUE}Step 1: Building ${CORE_NAME} core...${NC}"
    cd "$CORE_DIR"

    # Check where the Makefile actually is
    local ACTUAL_BUILD_DIR=""
    if [ -f "$MAKEFILE" ]; then
        # Makefile is in core root - run from here
        emmake make -f "$MAKEFILE" platform=emscripten clean
        emmake make -f "$MAKEFILE" platform=emscripten
        ACTUAL_BUILD_DIR="$CORE_DIR"
    elif [ -f "$BUILD_DIR/$MAKEFILE" ]; then
        # Makefile is in build subdirectory - cd there and run
        cd "$BUILD_DIR"
        emmake make -f "$MAKEFILE" platform=emscripten clean
        emmake make -f "$MAKEFILE" platform=emscripten
        ACTUAL_BUILD_DIR="$BUILD_DIR"
    else
        echo -e "${RED}Error: Cannot find $MAKEFILE in $CORE_DIR or $BUILD_DIR${NC}"
        return 1
    fi

    # Check if the core was built successfully
    # Output location varies: some cores output to BUILD_DIR, others to root
    local CORE_OUTPUT=""
    if [ -f "$BUILD_DIR/$CORE_FILE" ]; then
        CORE_OUTPUT="$BUILD_DIR/$CORE_FILE"
    elif [ -f "$CORE_DIR/$CORE_FILE" ]; then
        CORE_OUTPUT="$CORE_DIR/$CORE_FILE"
    else
        echo -e "${RED}Error: ${CORE_NAME} core build failed!${NC}"
        echo -e "${RED}Expected file: $BUILD_DIR/$CORE_FILE or $CORE_DIR/$CORE_FILE${NC}"
        return 1
    fi

    echo -e "${GREEN}✓ ${CORE_NAME} core built successfully${NC}"
    echo -e "${GREEN}Core output: $CORE_OUTPUT${NC}"

    # Copy the core to RetroArch directory
    echo -e "\n${BLUE}Step 2: Copying ${CORE_NAME} core to RetroArch...${NC}"
    cp "$CORE_OUTPUT" "$RETROARCH_DIR/libretro_emscripten.bc"    # Build RetroArch with the core
    echo -e "\n${BLUE}Step 3: Building RetroArch web player with ${CORE_NAME}...${NC}"
    cd "$RETROARCH_DIR"
    echo "Cleaning previous RetroArch build..."
    emmake make -f Makefile.emscripten clean
    emmake make -f Makefile.emscripten LIBRETRO=$CORENAME HAVE_XMB=1 HAVE_OZONE=1 HAVE_MATERIALUI=1 HAVE_CHEEVOS=1 -j$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4) all

    # Check if RetroArch was built successfully
    if [ ! -f "$RETROARCH_DIR/${CORENAME}_libretro.js" ] || [ ! -f "$RETROARCH_DIR/${CORENAME}_libretro.wasm" ]; then
        echo -e "${RED}Error: RetroArch build failed for ${CORE_NAME}!${NC}"
        return 1
    fi

    echo -e "${GREEN}✓ RetroArch built successfully with ${CORE_NAME}${NC}"

    # Copy output files to web directory
    echo -e "\n${BLUE}Step 4: Copying output to web directory...${NC}"
    mkdir -p "$WEB_DIR"
    cp "$RETROARCH_DIR/${CORENAME}_libretro.js" "$WEB_DIR/"
    cp "$RETROARCH_DIR/${CORENAME}_libretro.wasm" "$WEB_DIR/"

    # Also copy JS/WASM outputs to a top-level build/ directory so they're easy to find
    echo -e "\n${BLUE}Step 4b: Copying output to build directory (${BUILD_OUTPUT_DIR})...${NC}"
    mkdir -p "$BUILD_OUTPUT_DIR"
    # Copy both files and keep original names
    cp -f "$RETROARCH_DIR/${CORENAME}_libretro.js" "$BUILD_OUTPUT_DIR/"
    cp -f "$RETROARCH_DIR/${CORENAME}_libretro.wasm" "$BUILD_OUTPUT_DIR/"

    echo -e "\n${GREEN}✓ ${CORE_NAME} build complete!${NC}"
    echo -e "${GREEN}Output files:${NC}"
    echo -e "  - $WEB_DIR/${CORENAME}_libretro.js"
    echo -e "  - $WEB_DIR/${CORENAME}_libretro.wasm"
    echo -e "  - $BUILD_OUTPUT_DIR/${CORENAME}_libretro.js"
    echo -e "  - $BUILD_OUTPUT_DIR/${CORENAME}_libretro.wasm"
}

# Main script
main() {
    # Check arguments
    if [ $# -eq 0 ]; then
        echo -e "${RED}Error: No cores specified${NC}\n"
        print_usage
        exit 1
    fi

    # Check emsdk
    check_emsdk

    # Determine which cores to build
    local CORES_TO_BUILD=()
    if [ "$1" == "all" ]; then
        CORES_TO_BUILD=("${AVAILABLE_CORES[@]}")
    else
        CORES_TO_BUILD=("$@")
    fi

    echo -e "\n${BLUE}Cores to build: ${CORES_TO_BUILD[*]}${NC}\n"

    # Build each core
    local SUCCESS_COUNT=0
    local FAIL_COUNT=0
    local FAILED_CORES=()

    for core in "${CORES_TO_BUILD[@]}"; do
        if build_core "$core"; then
            ((SUCCESS_COUNT++))
        else
            ((FAIL_COUNT++))
            FAILED_CORES+=("$core")
        fi
    done

    # Summary
    echo -e "\n${GREEN}========================================${NC}"
    echo -e "${GREEN}Build Summary${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}Successful builds: $SUCCESS_COUNT${NC}"
    if [ $FAIL_COUNT -gt 0 ]; then
        echo -e "${RED}Failed builds: $FAIL_COUNT${NC}"
        echo -e "${RED}Failed cores: ${FAILED_CORES[*]}${NC}"
    fi

    if [ $SUCCESS_COUNT -gt 0 ]; then
        echo -e "\n${YELLOW}Note: Make sure you have the required assets in $WEB_DIR/assets/${NC}"
        echo -e "${YELLOW}You can download them from: https://buildbot.libretro.com/nightly/emscripten/${NC}"
    fi

    # Exit with error if any builds failed
    [ $FAIL_COUNT -eq 0 ]
}

# Run main function
main "$@"
