-- Run: lua verify_ir_beacon.lua "path/to/Scripts/IR_Runway.lua"
local script = assert(arg[1], "pass IR_Runway.lua path")
local objects, units, events, flags, spots, errors = {}, {}, {}, {}, {}, {}
local runwayZones = {}
local clock, nextId, spawns, farps = 0, 0, 0, 0
local function object(name, x, y, z, kind)
  local obj = { name = name, life = 1, point = { x = x, y = y, z = z }, kind = kind }
  function obj:isExist() return true end
  function obj:getLife() return self.life end
  function obj:getTypeName() return self.kind end
  function obj:getPoint() return self.point end
  function obj:getDesc() return { box = { min = { y = -0.5 }, max = { y = 1.5 } } } end
  function obj:getPosition()
    -- Rotated heading exercises the world-to-local IR origin conversion.
    return { p = self.point, x = { x = 0, y = 0, z = 1 },
      y = { x = 0, y = 1, z = 0 }, z = { x = -1, y = 0, z = 0 } }
  end
  return obj
end
local beaconType = "USLANTCOM_I2_BEACON"
objects.IR_STROBE_2 = object("IR_STROBE_2", 20, 100, 30, beaconType)
units.IR_STROBE_3 = object("IR_STROBE_3", 40, 100, 50, beaconType)
units.Truck = object("Truck", 60, 100, 70, "Truck")
objects.IR_STROBE_6__I2 = object("unrelated", 0, 0, 0, "Container")
StaticObject = { getByName = function(name) return objects[name] end }
Unit = { getByName = function(name) return units[name] end }
country = { id = { USA = 2 } }
coalition = {
  addStaticObject = function(id, data)
    assert(id == 2 and data.type == beaconType and data.category == "Fortifications")
    assert(not objects[data.name] and not units[data.name], "must not replace existing objects")
    if data.name == "IR_STROBE_5__I2" then error("mod unavailable") end
    spawns = spawns + 1
    objects[data.name] = object(data.name, data.x, 100, data.y, data.type)
    return objects[data.name]
  end,
  addGroup = function()
    farps = farps + 1
    error("no shared FARP/group source is permitted")
  end,
}
timer = {
  getTime = function() return clock end,
  scheduleFunction = function(fn, args, time)
    nextId = nextId + 1; events[nextId] = { fn = fn, args = args, time = time }; return nextId
  end,
  removeFunction = function(id) events[id] = nil end,
}
local function advance(to)
  while true do
    local id, event
    for key, value in pairs(events) do
      if value.time <= to and (not event or value.time < event.time) then id, event = key, value end
    end
    if not event then break end
    clock = event.time
    local again = event.fn(event.args, clock)
    if events[id] == event then
      if again then event.time = again else events[id] = nil end
    end
  end
  clock = to
end
trigger = { action = { outText = function() end }, misc = {
  getUserFlag = function(flag) return flags[flag] or 0 end,
  getZone = function(name)
    if name == "IR_RWY_START" or name == "IR_RWY_END" then return runwayZones[name] end
    if name == "IR_STROBE_4" then return { point = units.Truck.point } end
    return { point = { x = 10, y = 100, z = 15 } }
  end,
} }
land = { getHeight = function() return 100 end }
Spot = { createInfraRed = function(source, offset, target)
  assert(source:getTypeName() == beaconType, "every IR spot must use an I2 source")
  assert(source:getLife() > 0)
  if source.name == "IR_STROBE_4__I2" then
    assert(target.x == units.Truck.point.x, "linked zone uses its own I2 source")
  else
    assert(target.x == source:getPoint().x, "fixed beacon must use itself as source")
  end
  local p = source:getPosition()
  local world = {}
  for _, axis in ipairs({ "x", "y", "z" }) do
    world[axis] = p.p[axis] + p.x[axis] * offset.x + p.y[axis] * offset.y + p.z[axis] * offset.z
  end
  assert(math.abs(world.x - target.x) < 1e-8 and math.abs(world.z - target.z) < 1e-8)
  local beamLength=math.sqrt((world.x-target.x)^2+(world.y-target.y)^2+(world.z-target.z)^2)
  assert(beamLength<1e-8, "IR source and target must coincide: no pointer beam")
  local spot = { target = target }
  function spot:destroy() self.dead = true end
  spots[#spots + 1] = spot
  return spot
end }
env = { error = function(message) errors[#errors + 1] = message end, info = function() end,
  mission = { triggers = { zones = {
    { name = "IR_STROBE_1" }, { name = "IR_STROBE_2" },
    { name = "IR_STROBE_4", linkUnit = 44 }, { name = "IR_STROBE_5" },
    { name = "IR_STROBE_6" }, { name = "IR_STROBE_BAD" },
  } }, coalition = { blue = { country = { { static = { group = { { units = {
    { name = "IR_STROBE_2", type = beaconType, x = 20, y = 30 },
  } } } }, vehicle = { group = { { units = {
    { name = "IR_STROBE_3", type = beaconType, x = 40, y = 50 },
    { name = "Truck", type = "Truck", unitId = 44 },
  } } } } } } } } },
}
local function active()
  local result = {}
  for _, spot in ipairs(spots) do if not spot.dead then result[#result + 1] = spot.target end end
  return result
end
dofile(script)
assert(#IR_RUNWAY.points == 6 and spawns == 2 and farps == 0 and #errors == 2)
advance(0.2); assert(#active() == 0)
flags[1], flags[2], flags[3], flags[4], flags[5], flags[6] = 1, 1, 2, 1, 1, 1
advance(0.4)
assert(#active() == 4 and farps == 0, "all strobe sources must be I2 objects")
local targets = {}; for _, p in ipairs(active()) do targets[p.x] = p end
assert(math.abs(targets[10].y - 100.042) < 1e-8, "I2 target must be just above its 32 mm housing")
assert(targets[20] and targets[40] and targets[60].y == 102, "placed positions override zones; linked height preserved")
advance(0.9); assert(#active() == 0, "half-second flash must end")
objects.IR_STROBE_1__I2.life = 0
flags[2] = 0
units.Truck.point.x = 80
advance(1.4)
assert(#active() == 2 and spawns == 2, "dead beacon and disabled flag must not flash or respawn")
targets = {}; for _, p in ipairs(active()) do targets[p.x] = p end
assert(targets[80] and targets[40], "linked strobe must track moving unit")
for flag = 1, 6 do flags[flag] = 0 end
advance(1.7); assert(#active() == 0 and not IR_RUNWAY.active, "flags off clear spots")
flags[3] = 1; advance(1.9); assert(#active() == 1)
local old = IR_RUNWAY
dofile(script)
assert(not old.active and not old.watch_timer and #active() == 0 and spawns == 2 and farps == 0)
advance(2.1); assert(#active() == 1 and farps == 0, "reload reuses objects and single timer chain")
units.IR_STROBE_3.life = 0
advance(3.2); assert(#active() == 0, "destroyed placed unit must stop")
IR_RUNWAY.shutdown(); assert(next(events) == nil and #active() == 0)
-- Runway-only mission: both endpoints, <=30 m spacing, one flag and no beam.
env.mission = {triggers={zones={}},coalition={}}
runwayZones.IR_RWY_START = {point={x=200,y=100,z=300}}
runwayZones.IR_RWY_END = {point={x=260,y=100,z=380}}
dofile(script)
assert(IR_RUNWAY.runway_count==5 and #IR_RUNWAY.points==5)
local first,last=IR_RUNWAY.points[1],IR_RUNWAY.points[5]
assert(first.x==200 and first.y==300 and last.x==260 and last.y==380)
for i,p in ipairs(IR_RUNWAY.points) do
  assert(p.flag==9001)
  if i>1 then
    local prev=IR_RUNWAY.points[i-1]
    assert(math.sqrt((p.x-prev.x)^2+(p.y-prev.y)^2)<=30)
  end
end
advance(3.4);assert(#active()==0)
flags[9001]=1;advance(3.6);assert(#active()==5)
flags[9001]=0;advance(3.9);assert(#active()==0)
IR_RUNWAY.shutdown();assert(next(events)==nil)
print("OK: I2 spawn/reuse, placed static + ground unit, flags, timing, destruction, linked movement, failures, reload and cleanup")
print("OK: flag 9001 runway row, endpoints/spacing and coincident IR endpoints (no beam)")
