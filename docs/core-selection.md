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
