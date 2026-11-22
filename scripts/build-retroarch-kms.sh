#!/usr/bin/env bash
# Reproducible ARMv7 RetroArch KMS build at the pinned upstream commit.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
RA_REPO="https://github.com/libretro/RetroArch.git"
RA_COMMIT="7872266"
PATCH="$REPO_ROOT/patches/retroarch-7872266-lima-rgb565.patch"
WORK="${WORK:-/tmp/opencode/retroarch-pinned}"
OUT="${OUT:-/tmp/opencode/retroarch-kms-pinned}"
IMAGE="${IMAGE:-debian:trixie}"

if [ ! -d "$WORK/.git" ]; then
  git clone --filter=blob:none --no-checkout "$RA_REPO" "$WORK"
fi
git -C "$WORK" checkout -q -f "$RA_COMMIT"
git -C "$WORK" clean -fdq

# Reviewable 155-line patch replaces the full 11k-line drop-in as the source of truth.
git -C "$WORK" apply --check "$PATCH"
git -C "$WORK" apply "$PATCH"

docker run --rm --platform linux/arm/v7 -v "$WORK:/ra" "$IMAGE" bash -c '
  set -e
  apt-get update -qq
  DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
    build-essential pkg-config libdrm-dev libgbm-dev libegl1-mesa-dev \
    libgles2-mesa-dev libfreetype6-dev fontconfig libasound2-dev
  cd /ra
  ./configure \
    --enable-kms --enable-opengles --disable-opengl \
    --disable-x11 --disable-wayland --disable-vulkan --disable-sdl2 \
    --disable-discord --disable-oss --disable-jack --disable-qt \
    --disable-parport --disable-hid
  make -j4
'

cp "$WORK/retroarch" "$OUT"
chmod 755 "$OUT"
echo "built $OUT"
sha256sum "$OUT"
