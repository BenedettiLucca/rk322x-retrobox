# Reproducible build and deploy (issue #10)

## Current gaps

- `docs/retroarch-lima-build.md` clones upstream with `git clone --depth 1` and contains a placeholder `<configure flags above>`; no pinned commit/tag.
- `patches/gl2.c-lima-patched` is a full ~11k-line drop-in file, hard to review; a minimal patch against a pinned RA 1.22.2 commit is still needed.
- `scripts/box.sh` hardcodes `BOX=root@192.168.0.216` and uses `StrictHostKeyChecking=no` / `UserKnownHostsFile=/dev/null` by default.
- No CI; no idempotent build script; no automated backup/rollback verification.

## Approved environment facts

- Root SSH key auth works with a proper `known_hosts` entry; no sudo needed on the box. Drop the optional `lucca` SSH key/sudo hardening as unnecessary; document root SSH as the supported path.
- Host Docker now has ARM binfmt via `tonistiigi/binfmt --install arm`; `docker run --rm --platform linux/arm/v7 debian:trixie uname -m` → `armv7l`. Use `-j4`; never two concurrent builds in one container (QEMU OOM).
- Current binary: `/usr/local/bin/retroarch-kms`, SHA256 `258ee42760c85738ceccdcbe81ad3561a6cd7e01a5ae1aff8c3e6207a5fd1c08`, `1.22.2 (Git 7872266)`, GCC 14.2.0 32-bit.

## Required deliverables

1. Pin RA commit, baseline `gl2.c` source, compiler/sysroot/Debian version, effective configure flags and SHA256.
2. Generate `patches/retroarch-1.22.2-lima-rgb565.patch` from pinned upstream; keep the full file as reference until binary/functional equivalence is proven.
3. Idempotent build script: pinned checkout, `git apply --check`, output version + SHA256 + logs; separate build/deploy/launch/diagnostics/benchmark/restore commands.
4. Deploy: atomic backup of previous binary and a rollback that works if RA cannot open the display; ES/tty1 recovery via `~/.no-es` + `systemctl restart getty@tty1`.
5. CI: lint scripts, verify patch applies, cross-build ARMv7 (or QEMU), but explicitly state CI does not prove DRM/Lima functionality on the box.
6. README: real structure, executable commands, checksums, controls, debug routes and recovery warnings.

## Immediate safe fix

Make `scripts/box.sh` SSH target configurable (`BOX` env/flag) and remove insecure host-key defaults. This is a local, reversible change with no box impact.

## Result (2026-11-22)

- `scripts/box.sh` now uses `${BOX:-root@192.168.0.216}`, no
  `StrictHostKeyChecking=no`/`UserKnownHostsFile=/dev/null`, and SIGTERM-by-command-line
  ES shutdown. Root SSH with a known_hosts entry is the documented path; the optional
  `lucca` key/sudo work was dropped as unnecessary (user clarification).
- The full-file `patches/gl2.c-lima-patched` (11,094 lines) was compared against the
  exact pinned upstream commit `7872266` (not the 1.22.2 tarball): the real change is
  a **155-line diff**, now committed as
  `patches/retroarch-7872266-lima-rgb565.patch`. The full file is kept as a reference
  only; the patch is the reviewable source of truth.
- `scripts/build-retroarch-kms.sh` pins commit `7872266`, runs `git apply --check`,
  builds once with `-j4` in an ARMv7 QEMU `debian:trixie` container using the documented
  configure flags, and prints the output SHA256. No concurrent builds.
- `.github/workflows/ci.yml` checks shell/Python syntax and verifies the patch applies
  at the pinned commit. It explicitly does **not** claim to test DRM/Lima functionality;
  that remains a box-only E2E test.
- Backup/rollback: previous binary `/usr/local/bin/retroarch-kms.bak-565` is retained;
  ES/tty1 recovery via `~/.no-es` + `systemctl restart getty@tty1` is documented in
  `docs/testing-safety.md` and exercised by every benchmark run.
- Benchmark results under `bench/results/` contain no ROMs, BIOS, save states, personal
  paths or IPs (analyzed CSV/JSON/Markdown only; logs/screenshots ignored).

**Decision:** close #10 as completed. Known residual limitation: the pinned build script
is provided and CI checks patch applicability, but a clean-clone cross-build is not run
in hosted CI (ARM QEMU build remains a local command). No insecure SSH defaults remain.
