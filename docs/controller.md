# Controller: Xbox 360 Wireless Receiver (udev)

Device: `/dev/input/event1`, `045e:02a1`, driver `xpad`.

## How the mapping was derived

Don't trust saved autoconfigs blindly — the box had one with `select=10,
start=11, dpad=16-19` saved by an earlier session; buttons 11+ **don't exist**
on this device, which is why d-pad and sticks were dead while face buttons
worked by luck.

Decode the truth from sysfs:

```sh
cat /sys/class/input/event1/device/capabilities/abs
# 3003f → axes 0-5 (X,Y,Z,RX,RY,RZ = sticks + analog triggers) + 16,17 (HAT0 = d-pad)
cat /sys/class/input/event1/device/capabilities/key
# word8 = 0x7cdb0000 → codes 272,273,275,276,278,279,282,283,284,285,286
```

RA's udev driver numbers buttons by enumeration order from `BTN_MISC` (0x100):

| evdev code | legacy name | meaning | RA udev idx |
|---|---|---|---|
| 272 | BTN_A | south (Xbox A) | 0 |
| 273 | BTN_B | east (Xbox B) | 1 |
| 275 | BTN_X | north (Xbox Y) | 2 |
| 276 | BTN_Y | west (Xbox X) | 3 |
| 278/279 | BTN_TL/TR | LB/RB | 4/5 |
| 282 | BTN_MODE | guide | 6 |
| 283/284 | BTN_SELECT/START | back/start | 7/8 |
| 285/286 | BTN_THUMBL/R | L3/R3 | 9/10 |

D-pad is a **hat** → autoconfig strings `h0up/h0down/h0left/h0right`.
Triggers are **axes** 2 (L2) and 5 (R2).

## Final binds (see ../config/)

RetroPad convention mapped onto Xbox layout (B=bottom, A=east, Y=west, X=north):

| RetroPad | Xbox physical | bind |
|---|---|---|
| B / A | A (bottom) / B (east) | 0 / 1 |
| Y / X | X (west) / Y (north) | 3 / 2 |
| Select / Start | back / start | 7 / 8 |
| L3 / R3 | stick clicks | 9 / 10 |
| D-pad | hat | h0up/… |

⚠️ A/B and X/Y look "swapped" versus Xbox labels — that's correct; RetroPad
follows Nintendo layout. We initially had A/B reversed, which Sonic masked
(any button jumps) and DS games exposed immediately.

## Hotkeys

- **Guide+Start** = quit emulator (`input_exit_emulator_btn = 8`)
- **Guide+Select** = RetroArch menu (`input_menu_toggle_btn = 7`)
- **Start+Select** = menu via built-in combo (`input_menu_toggle_gamepad_combo = "1"` in the main cfg) — survives broken autoconfig binds

Install location on the box:
`~/.config/retroarch/autoconfig/Xbox 360 Wireless Receiver.cfg`
(delete `.autoconfig_index` after editing, or a stale index may shadow it).
