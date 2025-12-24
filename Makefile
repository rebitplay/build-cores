# Makefile for building RetroArch web cores using build-cores.sh
# Default target: build all cores

SHELL := /bin/zsh
BUILD_SCRIPT := ./build-cores.sh

.PHONY: default help build build-core clean clean-core

default: build

# Build targets
# Usage:
#   make                 -> build all cores (default)
#   make build CORES=all -> build specified cores (CORES can be 'all' or a space-separated list)
#   make build-core CORE=fceumm -> build a single core

CORES ?= all

build:
	@echo "Building cores: $(CORES)"
	@$(BUILD_SCRIPT) $(CORES)

build-core:
	@if [ -z "$(CORE)" ]; then \
		echo "Error: specify CORE=<core> (e.g. CORE=fceumm)"; exit 1; \
	fi
	@echo "Building core: $(CORE)"
	@$(BUILD_SCRIPT) $(CORE)

# Clean build artifacts
clean:
	@echo "Cleaning build/ and web/*_libretro.* artifacts..."
	@rm -rf build
	@rm -rf RetroArch/obj-embscripten
	@find web -maxdepth 1 -type f -name "*_libretro.*" -print -delete || true
	@echo "Clean complete."

clean-core:
	@if [ -z "$(CORE)" ]; then \
		echo "Error: specify CORE=<core> (e.g. CORE=fceumm)"; exit 1; \
	fi
	@echo "Cleaning artifacts for core: $(CORE)"
	@rm -f build/$(CORE)_libretro.* web/$(CORE)_libretro.* || true
	@echo "Cleaned $(CORE)"

help:
	@echo "Makefile targets:"
	@echo "  make            # build all cores (default)"
	@echo "  make build CORES=all|fceumm|snes9x|mgba|melonds     # build specific cores"
	@echo "  make build-core CORE=fceumm             # build one core"
	@echo "  make clean                              # remove build/ and per-core outputs in web/"
	@echo "  make clean-core CORE=fceumm             # remove outputs for a single core"

playground:
	cd web && pnpm run dev
