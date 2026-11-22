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
