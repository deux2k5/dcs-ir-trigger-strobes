# DCS I2 IR Trigger-Zone Strobes

Flag-controlled IR strobes using the I2 beacon from the standalone
[USLANTCOM tech asset pack](https://github.com/deux2k5/uslantcom_asset_pack/tree/main/Mods/tech/USLANTCOM%20Asset%20Pack).
Every spawned source is an I2; no invisible FARP or FARP fallback is used.
No MOOSE or MIST dependency. The tech asset pack is required on all clients;
the USA aircraft pack is not required.

[Download the tech asset pack](https://github.com/deux2k5/uslantcom_asset_pack/releases/tag/i2-v1.0.0).
Extract its Mods folder into Saved Games/DCS so the plugin is at
`Mods/tech/USLANTCOM Asset Pack/entry.lua`. Remove the old aircraft-pack I2
registration if you installed the earlier development build; the tech pack
README gives migration instructions. Do not leave both copies registered.

## Mission Setup
1. Install the updated USLANTCOM tech asset pack and restart DCS.
2. Create a trigger zone named IR_STROBE_9002 where you want the beacon.
   A full-scale I2 prop spawns at the zone center when this script loads,
   even with its flag off. Radius is ignored. Spawn country defaults to USA.
3. Add MISSION START -> DO SCRIPT FILE -> IR_Runway.lua.
4. Set flag 9002 to 1 to flash, or 0 to stop. Each numeric suffix controls
   its own flag. Any nonzero numeric value enables it.
5. Re-select DO SCRIPT FILE after updating this file, then save the mission
   to embed the new version. Installing the pack alone does not load mission Lua.

## Manual Placement
Instead of a zone, place Static Objects -> Fortifications ->
I2 Beacon - USLANTCOM and set its object/unit name to IR_STROBE_9002.
The UNIT name is used, not the group name. A ground-unit I2 fortification
with that unit name also works. Use manual placement to choose heading,
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
there is no shared source, FARP spawning or FARP fallback.
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
not replace such objects. All clients need the USLANTCOM tech asset pack for its model.

## Offline Check
lua IR_Runway.lua
Integration check:
lua verify_ir_beacon.lua IR_Runway.lua
