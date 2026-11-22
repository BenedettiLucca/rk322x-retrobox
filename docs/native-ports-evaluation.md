# Native ARMv7/GLES2 ports and N64 recomp (issues #14 and #18)

## Asset and platform status

- Platform: RK3229, 4× Cortex-A7 ARMv7/armhf, Mali-400 MP2 with Mesa Lima, GLES2 only (no Vulkan/GLES3), 1 GB RAM, no X11/Wayland desktop; ES runs on tty1 with SDL2/KMS.
- SM64: user-provided `Super Mario 64 (USA).7z` extracted locally to `/tmp/opencode/sm64/baserom.us.z64` (8,388,608 B, SHA256 `17ce077343c6133f8c9f2d6d6d9a4ab62c8cd2aa57c40aea1f490b4c8bb21d91`). #14 Track A is unblocked; never commit the ROM.
- OpenLara/DevilutionX (#18): no Tomb Raider or Diablo data available; blocked. Document exact data/build path but do not proceed.
- ScummVM (#18): use freeware assets only; verify whether the Libretro ScummVM core already works in the current RA KMS build before any standalone port.

## #14 Track A (sm64ex)

Pin an upstream commit; build with an `arm-linux-gnueabihf` sysroot or QEMU ARMv7, using `-mcpu=cortex-a7`, ARMv7/NEON ABI checks. Review `TARGET_RPI=1` and remove Pi/VC4/V3D assumptions; reuse generic SDL2 + GLES2. Verify the renderer is Lima GLES2, not desktop GL/GL3/llvmpipe. If SDL2 KMSDRM/GBM/EGL is genuinely supported, coordinate DRM master with ES handoff; otherwise implement/enable a KMS/GBM/EGL path similar to custom RA. Test at 720p60 only (EDID confirms), native/low render resolution, no HD textures or heavy shaders. Validate Xbox 360 controller via udev/SDL, audio, saves and ES return. Benchmark with the #1 harness. Gate: no stable accelerated EGL/GLES2 window + input/audio → do not proceed to recomp.

## #14 Track B (N64Recomp + N64ModernRuntime)

Record discarded Zelda64Recomp + RT64 (Vulkan 1.2/D3D12 SM6, AArch64, not ARMv7). Investigate ARM32 support, 64-bit `uintptr_t`/alignment, endianness, MIPS 64-bit semantics, syscalls, overlays, heap and 1 GB limits. Compile/link ARMv7 first without GPU, then define a minimal game-specific GLES2 video interface from N64 display lists/state. Do not auto-convert Vulkan/RT64 to GLES2. Progressive playability: runtime → menu → first 3D scene → 5 min stable → audio/saves. Close with a reasoned infeasibility report if GLES3/Vulkan or CPU/RAM limits block it.

## #18 matrix

Compare pinned revision, license, ISA, toolchain, renderer, GLES version, EGL/GBM/KMSDRM support, SDL2 version, dependencies, asset requirements and effort. Quick validate `SDL_VIDEODRIVER=kmsdrm` on the box, renderer string, and no llvmpipe. Prioritize ScummVM (freeware), then note blocked DevilutionX/OpenLara. Do not promise 60 FPS for engines without a meaningful metric; use responsive/playable criteria and boot/menu/return measurements.

## Result (2026-11-22)

### #14 Track A — SM64 native port: PoC built and GPU-accelerated
- Source: `sm64pc/sm64ex` pinned locally at `/tmp/opencode/sm64ex` (the old
  `sm64-port/sm64ex` URL is gone). Legally owned `baserom.us.z64` (8,388,608 B) was
  used locally for asset extraction and is **not** committed.
- ARMv7 build: Debian trixie ARMv7 QEMU container with `build-essential`, `git`,
  `libstb-dev`, `bsdextrautils`, `libsdl2-dev`, `libgles-dev`, `libgles2`; plain
  `make TARGET_RPI=1 -j1` (no `CFLAGS` override — overriding drops `-I include`).
  Flags: `-march=armv7-a -mtune=cortex-a7 -mfpu=neon-vfpv4 -O3`, `-DUSE_GLES`,
  `-DRAPI_GL=1 -DWAPI_SDL2=1 -DHAVE_SDL2=1`, linked with `-lGLESv2 -lSDL2 -no-pie`.
- Binary: `build/us_pc/sm64.us.f3dex2e.arm`, 13,645,852 B, ELF32 ARM EABI5,
  BuildID `5826273b57a31ecc6deff5548df968105e5466dd`, deployed to the box as
  `/usr/local/bin/sm64ex` (not committed).
- Smoke test as `lucca` with `SDL_VIDEODRIVER=kmsdrm`: no crash, config/save dir
  created, 30 s run timed out as expected. `ldd` links `libGLESv2.so.2`,
  `libSDL2-2.0.so.0`, `libdrm.so.2`. 20 s strace: 348 `LIMA_GEM_SUBMIT`,
  173 `PAGE_FLIP`, 2 `MODE_SETCRTC` — Lima/GLES2 is active, no llvmpipe.
- Performance: after startup, page-flip median ~87.6 ms (~11.4 fps), p95 ~170 ms
  at the default 640×480 render target; early frames ~35 ms. This is a playability
  PoC, not a 60 FPS result.
- Limits: no screen capture tool on the box, so visual correctness was not verified
  independently; Xbox controller input, audio and save-state round-trips were not
  validated; ES integration was not added. These are required before any default
  change. The maintenance cost of a second graphics/input stack is not justified.

**Decision:** Track A is a successful accelerated PoC but not a replacement for the
Libretro path. Do not add it to ES or make it a default. Close #14 with the PoC
evidence plus the Track B negative result.

### #14 Track B — N64Recomp: infeasible
`N64Recomp` and `N64ModernRuntime` sources were inspected locally: the runtime is
x86_64/AArch64-only (64-bit pointers/`uintptr_t`, alignment and allocator assumptions)
and recommends RT64/Vulkan, which Mali-400/Lima cannot provide. No ARMv7/armhf target
exists. Zelda64Recomp additionally requires Vulkan 1.2/D3D12 SM6 and is AArch64-only.
**Close Track B with a negative result:** static N64 recomp is infeasible on this box
without a new ARMv7 runtime and a GLES2 renderer replacement.

### #18 — blocked / not planned
- OpenLara and DevilutionX: no Tomb Raider/Diablo game data available; no build or
  smoke test performed. Documented as blocked, not as a performance result.
- ScummVM: source cloned (`/tmp/opencode/scummvm`) but no freeware game data or ARMv7
  SDL2/KMSDRM smoke test was completed. The Libretro ScummVM core is not installed in
  the current RA build, so there is no baseline to migrate from.
- No native-port build, deploy or ES entry was added; no llvmpipe claim is made.

Close #18 with a blocked decision: revisit only when legal game data and a pinned
ARMv7/GLES2/KMSDRM build are available.
