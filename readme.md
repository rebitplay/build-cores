# RetroArch WASM Build System

This project builds RetroArch cores for WebAssembly/Emscripten.

## Supported Cores

- **fceumm** - NES/Famicom emulator
- **snes9x** - SNES emulator
- **mgba** - Game Boy Advance emulator

## Prerequisites

1. **Emscripten SDK** - Install and activate emsdk:
	```bash
	# Install emsdk (if not already installed)
	git clone https://github.com/emscripten-core/emsdk.git
	cd emsdk
	./emsdk install latest
	./emsdk activate latest

	# Activate for current session
	source ./emsdk_env.sh
	```

2. **Git** - For cloning core repositories

## Quick Start

### 1. Clone Core Repositories

Clone the cores you want to build:

```bash
# Clone all cores
./setup-cores.sh

# Or clone specific cores
./setup-cores.sh snes9x mgba
```

### 2. Build Cores

You can use the original build script or the top-level `Makefile` (recommended).

Using the script directly:

```bash
# Build a single core
./build-cores.sh fceumm

# Build multiple cores
./build-cores.sh fceumm snes9x mgba

# Build all available cores
./build-cores.sh all
```

Using the Makefile (preferred) — default target builds all cores:

```bash
# build all cores (default)
make

# build specific cores
make build CORES="fceumm snes9x"

# build a single core directly
make build-core CORE=fceumm

# remove all build artifacts (web/ and top-level build/)
make clean

# remove build artifacts for one core
make clean-core CORE=fceumm
```

## Output

Built files will be placed in both the `web/` directory (for the web player) and a new top-level `build/` directory so they're easy to find and reuse.

web/ (used by the web player):
- `<corename>_libretro.js` - JavaScript loader
- `<corename>_libretro.wasm` - WebAssembly binary

For example:
- `web/fceumm_libretro.js`
- `web/fceumm_libretro.wasm`
- `web/snes9x_libretro.js`
- `web/snes9x_libretro.wasm`

Top-level build/ (convenience copy of created artifacts):
- `build/fceumm_libretro.js`
- `build/fceumm_libretro.wasm`

## Project Structure

```
.
├── build-cores.sh          # Main build script
├── setup-cores.sh          # Clone core repositories
├── build-fceumm.sh        # Legacy build script (deprecated)
├── RetroArch/             # RetroArch repository
├── libretro-fceumm/       # FCEUMM core (clone with setup-cores.sh)
├── libretro-snes9x/       # SNES9X core (clone with setup-cores.sh)
├── libretro-mgba/         # mGBA core (clone with setup-cores.sh)
├── Makefile               # Helper Makefile to build/clean cores (default: build all)
└── web/                   # Build output directory
	 ├── fceumm_libretro.js
	 ├── fceumm_libretro.wasm
	 ├── retroarch.cfg
	 └── assets/            # RetroArch assets (download separately)
```

## Configuration

### RetroArch Configuration

The build includes a pre-configured `web/retroarch.cfg` with:
- Achievements enabled
- XMB menu driver (better UI than RGUI)
- Achievement menu visibility enabled

### Proxy Configuration

The lobby URL is configured in `RetroArch/file_path_special.h`:
```c
#define FILE_PATH_LOBBY_LIBRETRO_URL "https://proxy-api.daudau.cc/http://lobby.libretro.com/"
```

## Adding New Cores

To add support for a new core, edit `build-cores/setup-cores.sh`:

1. Add a repository mapping to the `CORE_REPOS` array:
	```bash
	CORE_REPOS+=("newcore=https://github.com/libretro/libretro-newcore.git")
	```

2. `AVAILABLE_CORES` is derived automatically from `CORE_REPOS`, so you don't need to update it manually.

3. Verify the core is known and clone the repository:
	```bash
	./setup-cores.sh list
	./setup-cores.sh newcore
	```

4. Build the new core:
	```bash
	./build-cores.sh newcore
	```

## Troubleshooting

### Emscripten not found
```
Error: Emscripten SDK not found!
```
**Solution**: Activate emsdk in your current terminal:
```bash
source /path/to/emsdk/emsdk_env.sh
```

### Core directory not found
```
Error: Core directory not found: /path/to/libretro-xxx
```
**Solution**: Clone the core repository first:
```bash
./setup-cores.sh corename
```

### Build fails with "stale object files"
**Solution**: The build script automatically cleans before building. If issues persist, manually clean:
```bash
cd RetroArch
emmake make -f Makefile.emscripten clean
```

## Assets

RetroArch requires additional assets (icons, fonts, etc.). Download from:
https://buildbot.libretro.com/nightly/emscripten/

Extract to `web/assets/` directory.

## License

Each core has its own license. See individual core repositories for details.
