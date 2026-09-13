# DCS IR Strobe Beacons

Standalone IR strobe beacon mod and flag-controlled IR strobe script for DCS World.
The model and textures are included; no aircraft asset pack is required.

## Install

1. [Download the standalone ZIP](https://github.com/deux2k5/dcs-ir-trigger-strobes/releases/latest).
2. Extract its `Mods` folder into your active `Saved Games/DCS` folder.
3. Restart DCS.

The mod should be at `Saved Games/DCS/Mods/tech/USLANTCOM IR Strobe Beacon/entry.lua`.
All multiplayer clients need the mod. Install either this standalone version
or the beacon supplied in USLANTCOM Tech Asset Pack, not both.

When upgrading, move the old `Mods/tech/USLANTCOM I2 Beacon` folder outside
`Mods` before extracting the renamed package. Existing mission objects keep
working because the internal `USLANTCOM_I2_BEACON` type is unchanged.

## Mission setup

Add **MISSION START → DO SCRIPT FILE → IR_Strobe_Beacons.lua** in the Mission Editor.
Use the script from this repository or the ZIP's mod `Scripts` folder.

- **Single strobe:** create a zone named `IR_STROBE_9002`. Set flag `9002` to `1`
  to flash or `0` to stop. Other `IR_STROBE_<number>` zones use their own flags.
- **Runway:** create zones `IR_RWY_START` and `IR_RWY_END`. Flag `9001` controls
  a row of steady IR beacons between them, spaced at most 30 metres apart.
- **Manual placement:** place `IR Strobe Beacon - USLANTCOM` as a static object and
  name the object `IR_STROBE_9002` to control it with flag `9002`.

Individual strobes flash for 0.5 seconds, once per second. Runway lights stay on
while flag `9001` is set, reusing their IR spots to avoid creating a new spot for
every runway beacon every second. Clearing the flag or shutting down/reloading
the script cleans up its runway spots.
Runway props are treated as permanent by default (`runway_check_health = false`):
their health is checked when creating a spot, with no periodic health checks
afterward. If damage or another script can delete your runway props, set
`runway_check_health = true` to check active sources every 0.25 seconds and
release their spots when destroyed. The model declares `Life = 1`; this setting
does not make it invulnerable. Individual and vehicle/ship strobes retain their
source/linked-unit health checks regardless of this setting.
Shared flags are read once per poll. Flash-off timers only run when
individual strobes actually emit a flash.
IR endpoints coincide
to remove the pointer beam. View the effect through night vision.
After updating the script, re-select it in DO SCRIPT FILE and save the mission.
Replace the old `IR_Runway.lua` selection with `IR_Strobe_Beacons.lua`; load only
one version. Existing zone names, flags and the `IR_RUNWAY` scripting API remain compatible.

## Moving strobe (vehicle or ship)

1. Place the vehicle or ship and give it a route.
2. Create a trigger zone named `IR_STROBE_9003`, centred on that unit's starting
   position. The zone radius does not matter.
3. In the zone settings, use **LINK UNIT** to select the specific vehicle or ship.
4. Load `IR_Strobe_Beacons.lua` using the mission setup above. Set flag `9003` to `1`
   to flash, or `0` to stop. Use another numeric suffix for a separate flag.

The IR flashes follow the linked zone as the unit moves. Only the light effect
moves: the spawned IR strobe beacon model stays at the zone's initial position. Flashes stop
if the linked unit or source beacon is destroyed.

Use a linked zone for this setup; do not also place a static beacon with the
same name, because that would override the moving zone. Keep runway endpoint
zones fixed on the ground.
