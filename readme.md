# RetroArch WASM Build System

This project builds RetroArch cores for WebAssembly/Emscripten.

## Supported Cores

- **fceumm** - NES/Famicom emulator
- **snes9x** - SNES emulator
- **mgba** - Game Boy Advance emulator
- **mgba_dual** - Rebit custom standalone mGBA WebAssembly runtime built from `git@github.com:rebitplay/mgba_dual.git` on branch `rebit`.
- **gpsp** - Rebit gpSP fork for browser RFU/link cable experiments from `https://github.com/rebitplay/gpsp.git` on branch `rebit`.
- **ppsspp** - Rebit PPSSPP fork for PlayStation Portable emulation from `https://github.com/rebitplay/ppsspp.git`.
- **azahar** - Rebit Azahar fork for Nintendo 3DS emulation from `https://github.com/rebitplay/azahar.git` on branch `rebit`.
- **vbam** - Rebit VBA-M fork for GBA link/Multi-Pak experiments from `git@github.com:rebitplay/visualboyadvance-m.git` on branch `rebit`.

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

# Clone the custom Rebit mGBA dual runtime
./setup-cores.sh mgba_dual

# Clone the custom Rebit gpSP fork
./setup-cores.sh gpsp

# Clone the Rebit PPSSPP fork
./setup-cores.sh ppsspp

# Clone the Rebit Azahar fork
./setup-cores.sh azahar

# Clone the custom Rebit VBA-M fork
./setup-cores.sh vbam

# Or use the local maintained fork directly
mkdir -p cores
ln -s /Users/daudau/Code/rebitplay/mgba_dual cores/libretro-mgba_dual
ln -s /Users/daudau/Code/rebitplay/gpsp cores/libretro-gpsp
ln -s /Users/daudau/Code/rebitplay/ppsspp cores/libretro-ppsspp
ln -s /Users/daudau/Code/rebitplay/azahar cores/libretro-azahar
ln -s /Users/daudau/Code/rebitplay/visualboyadvance-m cores/libretro-vbam
```

### 2. Build Cores

You can use the original build script or the top-level `Makefile` (recommended).

Using the script directly:

```bash
# Build a single core
./build-cores.sh fceumm

# Build multiple cores
./build-cores.sh fceumm snes9x mgba_dual gpsp ppsspp azahar vbam

# Build all available cores
./build-cores.sh all
```

Using the Makefile (preferred) — default target builds all cores:

```bash
# build all cores (default)
make

# build specific cores
make build CORES="fceumm snes9x mgba_dual gpsp ppsspp azahar vbam"

# build a single core directly
make build-core CORE=fceumm
make build-core CORE=gpsp
make build-core CORE=ppsspp
make build-core CORE=azahar
make build-core CORE=vbam

# remove all build artifacts (web/ and top-level build/)
make clean

# remove build artifacts for one core
make clean-core CORE=fceumm
```

To build gpSP from the maintained sibling checkout without replacing an existing `cores/libretro-gpsp` directory:

```bash
GPSP_SOURCE_DIR=/Users/daudau/Code/rebitplay/gpsp make build-core CORE=gpsp
```

To build PPSSPP from the maintained sibling checkout:

```bash
PPSSPP_SOURCE_DIR=/Users/daudau/Code/rebitplay/ppsspp make build-core CORE=ppsspp
```

To build Azahar from the maintained sibling checkout:

```bash
AZAHAR_SOURCE_DIR=/Users/daudau/Code/rebitplay/azahar make build-core CORE=azahar
```

## Output

Built files will be placed in both the `web/` directory (for the web player) and a new top-level `build/` directory so they're easy to find and reuse.
If `../rebit/public/cores` exists, the build script also copies the generated JS/WASM there.

web/ (used by the web player):
- `<corename>_libretro.js` - JavaScript loader
- `<corename>_libretro.wasm` - WebAssembly binary

For example:
- `web/fceumm_libretro.js`
- `web/fceumm_libretro.wasm`
- `web/snes9x_libretro.js`
- `web/snes9x_libretro.wasm`
- `web/mgba_dual_libretro.js`
- `web/mgba_dual_libretro.wasm`

Top-level build/ (convenience copy of created artifacts):
- `build/fceumm_libretro.js`
- `build/fceumm_libretro.wasm`
- `build/mgba_dual_libretro.js`
- `build/mgba_dual_libretro.wasm`

## Project Structure

```
.
├── build-cores.sh          # Main build script
├── setup-cores.sh          # Clone core repositories
├── Makefile                # Helper Makefile to build/clean cores (default: build all)
├── RetroArch/              # RetroArch repository
├── cores/                  # Core repositories (cloned with setup-cores.sh)
│   ├── libretro-fceumm/
│   ├── libretro-snes9x/
│   ├── libretro-mgba/
│   ├── libretro-mgba_dual/
│   ├── libretro-gpsp/
│   ├── libretro-ppsspp/
│   ├── libretro-azahar/
│   └── libretro-vbam/
├── build/                  # Build output directory (convenience copy)
└── web/                    # Build output directory (for web player)
    ├── fceumm_libretro.js
    ├── fceumm_libretro.wasm
    ├── mgba_dual_libretro.js
    ├── mgba_dual_libretro.wasm
    ├── retroarch.cfg
    └── assets/             # RetroArch assets (download separately)
```

## mGBA Dual Runtime

`mgba_dual` is not a libretro core. It is a standalone Emscripten runtime built from `cores/libretro-mgba_dual/rebit/emscripten`, exporting `createMGBAModule`, `mgba_demo_*`, and `mgba_remote_*`. Rebit's `/playground/mgba-link` and `/playground/mgba-dual` pages use the `mgba_demo_*` lockstep API.

```bash
./setup-cores.sh mgba_dual
# or:
mkdir -p cores
ln -s /Users/daudau/Code/rebitplay/mgba_dual cores/libretro-mgba_dual

make build-core CORE=mgba_dual
```

The target expects the fork at `cores/libretro-mgba_dual` and the wrapper at `cores/libretro-mgba_dual/rebit/emscripten`. The output files are `mgba_dual_libretro.js` and `mgba_dual_libretro.wasm`.

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
