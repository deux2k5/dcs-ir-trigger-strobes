# DCS I2 IR Strobes

Standalone I2 beacon mod and flag-controlled IR strobe script for DCS World.
The model and textures are included; no aircraft asset pack is required.

## Install

1. [Download the standalone ZIP](https://github.com/deux2k5/dcs-ir-trigger-strobes/releases/latest).
2. Extract its `Mods` folder into your active `Saved Games/DCS` folder.
3. Restart DCS.

The mod should be at `Saved Games/DCS/Mods/tech/USLANTCOM I2 Beacon/entry.lua`.
All multiplayer clients need the mod. Install either this standalone version
or the I2 supplied in the USLANTCOM Asset Pack, not both.

## Mission setup

Add **MISSION START → DO SCRIPT FILE → IR_Runway.lua** in the Mission Editor.
Use the script from this repository or the ZIP's mod `Scripts` folder.

- **Single strobe:** create a zone named `IR_STROBE_9002`. Set flag `9002` to `1`
  to flash or `0` to stop. Other `IR_STROBE_<number>` zones use their own flags.
- **Runway:** create zones `IR_RWY_START` and `IR_RWY_END`. Flag `9001` controls
  a row of beacons between them, spaced at most 30 metres apart.
- **Manual placement:** place `I2 Beacon - USLANTCOM` as a static object and
  name the object `IR_STROBE_9002` to control it with flag `9002`.

Default flashing is 0.5 seconds on, once per second. IR endpoints coincide
to remove the pointer beam. View the effect through night vision.
After updating the script, re-select it in DO SCRIPT FILE and save the mission.

## Moving strobe (vehicle or ship)

1. Place the vehicle or ship and give it a route.
2. Create a trigger zone named `IR_STROBE_9003`, centred on that unit's starting
   position. The zone radius does not matter.
3. In the zone settings, use **LINK UNIT** to select the specific vehicle or ship.
4. Load `IR_Runway.lua` using the mission setup above. Set flag `9003` to `1`
   to flash, or `0` to stop. Use another numeric suffix for a separate flag.

The IR flashes follow the linked zone as the unit moves. Only the light effect
moves: the spawned I2 model stays at the zone's initial position. Flashes stop
if the linked unit or source beacon is destroyed.

Use a linked zone for this setup; do not also place a static beacon with the
same name, because that would override the moving zone. Keep runway endpoint
zones fixed on the ground.
