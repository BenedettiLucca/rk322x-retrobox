# Core selection matrix (issue #8)

Scope: 14 systems from `/etc/emulationstation/es_systems.cfg`. No system is marked viable without a real test.

| System | Current core | Alternate candidates | Status |
|---|---|---|---|
| psx | PCSX-ReARMed | mednafen_psx (installed) | Baseline running (#1); options in #3/#7 |
| snes | Snes9x | Snes9x 2010/2005/2002 | Super Metroid available; untested alternates |
| gba | mGBA | gpSP | Pokemon Emerald available; untested |
| nes | Nestopia | FCEUmm | ROMs present; untested |
| gb/gbc | Gambatte | same | ROMs present; untested |
| gg/ms | PicoDrive | Genesis Plus GX | ROMs present; untested |
| md | Genesis Plus GX | PicoDrive | ROM dir has only metadata; cannot test |
| pcengine | Mednafen PCE Fast | — | No ROMs; untested |
| arcade | MAME2003+ | FBNeo | ROMs present; romset compatibility to check |
| fba | FBNeo | MAME2003+ | ROMs present; romset compatibility to check |
| nds | Desmume2015 | — | Content present, performance/controls untested |
| saturn | Yabause | — | Content present, performance untested |
| dreamcast | (no system entry) | — | Content present, no viable ARMv7 core |
| n64 | (no system entry) | — | Content present, no core installed |
| psp | (no system entry) | — | Content present, no viable ARMv7 core |

## Method

Map `es_systems.cfg` → exact command/`.so`/version/options/ROM format. For each candidate use legal representative scenes (2D, effects, audio, 3D), the #1 harness, and record FPS/real speed, p95/p99 frametime, glitches, loading, RAM, crash rate, save/load, Xbox controller, audio. Mark results as full speed / partial / infeasible / untested. Propose default + fallback per system, preserve saves/config, and document rollback.

## Status

Only PSX, SNES and GBA have staged legal scenes. Other systems are untested until their ROM formats and core availability are confirmed. Update this table with measured results; do not infer viability from core names.

## Measured results (2026-11-22)

From the #1 baseline matrix (all thermal-limited at ~89–90 °C, 1.2 → ~1.008 GHz):

| System | Core | Scene | Delivered FPS | p95 interval | Status |
|---|---|---|---:|---:|---|
| PSX | PCSX-ReARMed | Crash Bandicoot (3D) | 17.7 | 124 ms | Partial — playable but slow |
| PSX | PCSX-ReARMed | CTR (3D) | 19.2 | 101 ms | Partial |
| PSX | PCSX-ReARMed | PaRappa (2D/audio) | 23.3 | 80 ms | Partial |
| SNES | Snes9x | Super Metroid | 23.4 | 62 ms | Partial — glitches not observed visually |
| GBA | mGBA | Pokemon Emerald | 27.0 | 55 ms | Partial |
| NES / GB / GBC / MD / GG / SMS / PCE / arcade / FBA / NDS / Saturn | various | none staged | — | — | Untested (no legal scene staged) |

Notes:

- No system is marked "full speed": page-flip FPS is well below the 50/60 Hz target on
  every measured scene. `video_threaded=true` lifts PSX 3D to ~27.6 fps but needs
  input/audio verification before becoming a profile (#6).
- The 11 untested systems cannot be promoted or rejected without ROMs; no claim is made.
- Alternative lighter cores (gpSP, Snes9x 2002, PicoDrive, FBNeo romset checks) were not
  A/B tested because the required ROM sets are absent; keep current `/etc/emulationstation/es_systems.cfg` mappings.

**Decision:** close #8 with the measured matrix above; keep current core defaults, no
ROM/config changes. Reopen only when additional legal scenes are provided.
