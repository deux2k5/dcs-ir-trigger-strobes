# DCS IR Trigger-Zone Strobes

A small, dependency-free DCS World mission script. Each specially named trigger zone places one independently controlled blinking IR strobe at the zone center.

## Setup

1. Add `IR_Runway.lua` to a `MISSION START` trigger using **DO SCRIPT FILE**.
2. Place a trigger zone wherever you want a strobe.
3. Name it `IR_STROBE_<flag>`.
4. Set that flag to `1` to turn the strobe on and `0` to turn it off.

Examples:

| Trigger-zone name | Controlling flag |
| --- | ---: |
| `IR_STROBE_9002` | `9002` |
| `IR_STROBE_9003` | `9003` |

Zone radius is ignored. Names are case-sensitive and must end in a numeric flag.

## Moving strobes

To attach a strobe to a moving ground vehicle or ship, select its trigger zone and set **LINK UNIT** to that unit. The script refreshes the linked zone's center every flash and uses the unit model's bounding-box height to place the strobe above its roof. Its existing zone name still selects the controlling flag.

The extra clearance is `mount_clearance = 1` meter near the top of the script; adjust it only if a particular model needs it.

## Details

- One zone creates one strobe.
- Each strobe is controlled independently.
- One runtime `Invisible FARP` supplies the DCS source object for every IR spot.
- No MOOSE or MIST dependency.
- Default flash timing is 0.5 seconds on every 1 second; edit the values near the top of the script if desired.
- The source country defaults to USA.

After changing the Lua file, reselect it in **DO SCRIPT FILE** and save the mission so DCS embeds the updated copy.

## Quick check

With Lua installed:

```console
lua IR_Runway.lua
```

Expected output:

```text
OK: IR_STROBE_9002 is controlled by flag 9002
```
