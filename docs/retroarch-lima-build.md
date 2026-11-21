# Building RetroArch KMS/GLES for RK322X (armv7)

Debian's RetroArch package is built for X11/desktop GL; on a KMS-only TV box its
sdl2 driver falls back to llvmpipe (CPU) rendering. We build RA's native **kms**
video context driver (drmModeSetCrtc + GBM + EGL/GLES2 — the same path
EmulationStation uses internally) so the Mali-400 does all scaling.

## Configure flags

```sh
./configure --enable-kms --enable-opengles --disable-opengl \
  --disable-x11 --disable-wayland --disable-vulkan --disable-sdl2 \
  --disable-discord --disable-oss --disable-jack --disable-qt \
  --disable-parport --disable-hid
```

Notes learned the hard way:
- The GLES flag is **`--enable-opengles`** (not `--enable-gles`).
- Keep `--disable-opengl`: the legacy **gl1** fixed-function driver links against
  desktop GL symbols (`glVertex2f`...) and breaks the final link otherwise.
- Verify the result: `./retroarch --features | grep -iE "kms|opengles|egl"`.
- Runtime deps on the box: `libdrm2 libgbm1 libglvnd` + Mesa (lima) — all stock.

## Cross-build recipe (QEMU container, no toolchain needed)

```sh
docker run --name rabuild --platform linux/arm/v7 debian:trixie bash -c '
  apt-get update && apt-get install -y build-essential git pkg-config \
    libdrm-dev libgbm-dev libegl1-mesa-dev libgles2-mesa-dev \
    libfreetype6-dev fontconfig libaudiofile-dev libasound2-dev
  git clone --depth 1 https://github.com/libretro/RetroArch /ra
  cd /ra && <configure flags above> && make -j4 && echo OK'
```

- Use **`-j4` max**: `-j8` under QEMU gets the container OOM-killed (exit 137).
- **Never `docker start` a build container**: it re-runs the original CMD and
  races whatever you `docker exec`. To continue: `docker commit` to an image,
  then `docker run` a fresh container with an explicit `make` command.
- Drop in the patched `patches/gl2.c-lima-patched` as `gfx/drivers/gl2.c`
  before `make` — only `gl2.o` recompiles + link (~40 s warm).
- Full clean build ≈ 11–12 min under QEMU on a decent x86 host.

## Deploy

```sh
docker cp rabuild:/ra/retroarch /tmp/retroarch-kms
cat /tmp/retroarch-kms | ssh root@192.168.0.216 \
  'cat > /tmp/ra.bin && install -m755 /tmp/ra.bin /usr/local/bin/retroarch-kms'
```

Keep Debian's `retroarch` installed as fallback; only `/usr/local/bin/retroarch-kms`
is KMS-capable. See `scripts/` for the launch pattern (own config file so the
shared `video_driver = "kms"` can't break the Debian binary).
