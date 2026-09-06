# DCS I2 IR Trigger-Zone Strobes

Flag-controlled IR strobes with the standalone **USLANTCOM I2 Beacon** DCS tech mod.
The model, textures, native static registration and script are all included here.
No private repository access, USA aircraft pack, MOOSE or MIST is required.
Every spawned source is an I2; no invisible FARP or FARP fallback is used.

[Download the standalone I2 mod and script](https://github.com/deux2k5/dcs-ir-trigger-strobes/releases/tag/i2-v1.0.2).
Extract the ZIP's `Mods` folder into your active Saved Games/DCS profile:

```text
Saved Games/DCS/Mods/tech/USLANTCOM I2 Beacon/entry.lua
```

All multiplayer clients need the mod. Install **one I2 provider only**: this
standalone mod or the I2 included in the USLANTCOM Asset Pack. They use the
same `USLANTCOM_I2_BEACON` unit type so existing missions remain compatible.
When switching, move the old I2-providing mod outside `Mods` first. For an
older aircraft-pack build, remove its I2 registration and I2 files while
keeping the aircraft. Fully restart DCS after changing installed mods.

The download includes `Scripts/IR_Runway.lua` inside the mod folder. Embed
that file using DO SCRIPT FILE; installing the model does not load mission Lua.

## Mission setup

1. Install the standalone I2 mod and restart DCS.
2. Create a trigger zone named IR_STROBE_9002 where you want the beacon.
   A full-scale I2 prop spawns at the zone center when this script loads,
   even with its flag off. Radius is ignored. Spawn country defaults to USA.
3. Add MISSION START -> DO SCRIPT FILE -> IR_Runway.lua.
4. Set flag 9002 to 1 to flash, or 0 to stop. Each numeric suffix controls
   its own flag. Any nonzero numeric value enables it.
5. Re-select DO SCRIPT FILE after updating this file, then save the mission
   to embed the new version. Installing the pack alone does not load mission Lua.

## Runway Row (Flag 9001)
Place two zones named IR_RWY_START and IR_RWY_END. The script places a
single row of I2 beacons between their centers, including both endpoints.
All use flag 9001: nonzero = flashing, zero = off. Default maximum spacing
is 30 meters; adjust runway_spacing near the top of the script as needed.
The runway row coexists with independently controlled IR_STROBE_<flag>
zones and manually named beacons. No runway is generated if both endpoint
zones are absent. Keep these endpoint zones fixed on the ground.

## Manual Placement
Instead of a zone, place Static Objects -> Fortifications ->
I2 Beacon - USLANTCOM and set its object/unit name to IR_STROBE_9002.
The object/unit name is used, not the group name. Use the Static Objects
placement tool for this native static structure. Use manual placement to choose heading,
country or a supported elevated placement. Use a separate flag/name for
each beacon. A placed beacon overrides a zone with the same name, so it
does not spawn a duplicate. Its current position and orientation determine
the IR target location. Destroying the beacon stops its flashes.

## Moving Zones
Existing zones linked to vehicles/ships retain the upstream moving IR
marker behavior. Each gets an I2 source prop at its initial zone center.
The IR offset follows the linked zone; the physical static prop stays at
its spawn position. This does not attach a physical I2 to the vehicle.
Missing/destroyed linked units or destroyed source beacons stop the marker.

## Timing And Appearance
Default: 0.5 seconds on, once per second; flags checked every 0.25 seconds.
The head is only 50 x 50 x 32 mm. Test on pavement with terrain clutter
clear. The IR target is 10 mm above the head, adjustable with ir_clearance
at the top of the Lua. Every native Spot.createInfraRed call uses that
marker's I2 beacon as its source. All spawned objects are I2 beacons;
there is no shared source, FARP spawning or FARP fallback. IR source and
target are coincident: there is no pointer-beam segment above the strobe.
This is an IR-spot approximation, not a flashing EDM lens or a simulation
of the manufacturer's multiple wavelengths and angular output pattern.
NVG/FLIR visibility, occlusion, range and multiplayer behavior require
in-game testing; the offline checks do not establish those properties.

Only load this version once. It replaces the original IR_Runway.lua;
do not also load the upstream version. Re-loading shuts down its previous
timers/spots and reuses existing props. Stopping the script or setting
flags to zero leaves the physical props in place. Runtime-created props
are mission-session objects, not additions saved into Mission Editor.
Late-activated/manually spawned beacons after script initialization are
not discovered automatically. Enable/load their mission objects first.
Restart the mission after replacing the older script to clear any FARP
that the older version already spawned; this version does not delete it.

If a spawn fails, check the on-screen message and dcs.log. Reserved names
IR_STROBE_<flag>__I2 must not belong to unrelated objects. The script will
not replace such objects. All clients need the standalone I2 mod or the compatible asset-pack I2.

## Offline Check
lua IR_Runway.lua
Full integration check in the development workspace:
lua verify_ir_beacon.lua IR_Runway.lua

## Model

The I2 assembly includes its controller and cable: 3,136 visible triangles,
two materials and 24 collision triangles. Head dimensions are 50 x 50 x 32 mm;
other small dimensions are photographic estimates. Native type:
`USLANTCOM_I2_BEACON`; display name: `I2 Beacon - USLANTCOM`.
[Manufacturer dimension reference](https://tplogic.com/wp-content/uploads/brochureI2Beacon_v2.pdf).

## Build the standalone ZIP

Run `python build_release.py`. It packages only this repository's I2 mod,
the current root `IR_Runway.lua` and these instructions into
`dist/USLANTCOM_I2_Beacon_Standalone.zip`, with SHA-256 integrity checks.
Run `lua verify_i2_entry.lua "Mods/tech/USLANTCOM I2 Beacon"` to check registration.
