-- Run from the repository root: lua test_spots.lua
-- Exercise the real script with a deterministic DCS API/timer stub.
local now, nextId, created, live = 0, 0, 0, 0
local flagReads, objectLookups, positionReads = 0, 0, 0
local healthReads = 0
local duplicateDestroys = 0
local jobs, objects = {}, {}
local flags = { [9001] = 1, [9002] = 1, [9003] = 1 }
local zones = {
  IR_RWY_START = { point = { x = 0, z = 0 } },
  IR_RWY_END = { point = { x = 1320, z = 0 } },
  IR_STROBE_9002 = { point = { x = 10, z = 10 } },
  IR_STROBE_9003 = { point = { x = 20, z = 20 } },
}
env = {
  mission = { coalition = {}, triggers = { zones = {
    { name = "IR_STROBE_9002" }, { name = "IR_STROBE_9003" },
  } } },
  info = function() end,
  error = function(message) error(message) end,
}
trigger = {
  misc = {
    getZone = function(name) return zones[name] end,
    getUserFlag = function(flag)
      flagReads = flagReads + 1
      return flags[flag] or 0
    end,
  },
  action = { outText = function() end },
}
timer = {
  getTime = function() return now end,
  scheduleFunction = function(fn, arg, at)
    nextId = nextId + 1
    jobs[nextId] = { fn = fn, arg = arg, at = at }
    return nextId
  end,
  removeFunction = function(id) jobs[id] = nil end,
}
local function advance(untilTime)
  while true do
    local selected, at
    for id, job in pairs(jobs) do
      if job.at <= untilTime and (not at or job.at < at) then
        selected, at = id, job.at
      end
    end
    if not selected then break end
    local job = jobs[selected]
    now = at
    local again = job.fn(job.arg, now)
    if jobs[selected] then
      if again then job.at = again else jobs[selected] = nil end
    end
  end
  now = untilTime
end
country = { id = { USA = 2 } }
coalition = { addStaticObject = function(_, data)
  local object = { life = 100 }
  function object:isExist() return self.exists ~= false end
  function object:getLife()
    healthReads = healthReads + 1
    return self.life
  end
  function object:getTypeName() return data.type end
  function object:getPosition()
    positionReads = positionReads + 1
    return {
      p = { x = data.x, y = 0, z = data.y },
      x = { x = 1, y = 0, z = 0 },
      y = { x = 0, y = 1, z = 0 },
      z = { x = 0, y = 0, z = 1 },
    }
  end
  objects[data.name] = object
  return object
end }
StaticObject = { getByName = function(name)
  objectLookups = objectLookups + 1
  return objects[name]
end }
Unit = { getByName = function() return nil end }
land = { getHeight = function() return 0 end }
Spot = { createInfraRed = function(source, offset, target)
  local position = source:getPosition().p
  assert(math.abs(position.x + offset.x - target.x) < 1e-9)
  assert(math.abs(position.y + offset.y - target.y) < 1e-9)
  assert(math.abs(position.z + offset.z - target.z) < 1e-9)
  created, live = created + 1, live + 1
  local destroyed = false
  return { destroy = function()
    if destroyed then
      duplicateDestroys = duplicateDestroys + 1
      error("spot destroyed twice")
    end
    destroyed = true
    live = live - 1
  end }
end }

dofile("IR_Strobe_Beacons.lua")
advance(0.2)
assert(IR_RUNWAY.runway_count == 45 and created == 47 and live == 47)
advance(0.8)
assert(live == 45, "only the individual strobes should turn off")
advance(120)
assert(created == 45 + 2 * 120, "runway spots must be reused across pulses")
assert(live == 45)
print(string.format("120s API calls: flags=%d, object lookups=%d, positions=%d",
  flagReads, objectLookups, positionReads))
assert(flagReads == 3 * 480, "read each shared flag only once per poll")
assert(objectLookups <= 332, "steady spots must retain their source handles")
assert(positionReads <= 570, "avoid duplicate position reads per creation")
assert(healthReads == created, "default runway mode checks health only at creation")

flags[9001] = 0
advance(120.4)
assert(live == 2, "runway flag must clean up while strobes remain enabled")
advance(120.8)
assert(live == 0)
flags[9001], flags[9002], flags[9003] = 1, 0, 0
advance(121.8)
assert(live == 45, "runway must restart without enabling individual strobes")
assert(not IR_RUNWAY.off_timer, "steady-only lights need no flash-off timer")
objects.IR_RWY_000__I2.life = 0
local beforeHealth = healthReads
advance(122.3)
assert(healthReads == beforeHealth and live == 45, "permanent runway mode must skip periodic health checks")
IR_RUNWAY.runway_check_health = true
advance(122.8)
assert(live == 44, "a destroyed runway beacon must lose its spot")
flags[9001] = 0
advance(123.2)
assert(live == 0 and not IR_RUNWAY.active)

flags[9001], flags[9002], flags[9003] = 1, 1, 1
advance(123.4)
assert(live == 46)
local previous = IR_RUNWAY
dofile("IR_Strobe_Beacons.lua")
assert(live == 0 and not previous.active and not previous.watch_timer)
IR_RUNWAY.runway_check_health = true
advance(123.6)
assert(live == 46, "reload must reuse props without duplicating spots")
local removed = objects.IR_RWY_001__I2
removed.exists = false
objects.IR_RWY_001__I2 = nil
advance(123.9)
assert(live == 45, "an expired cached source must release its spot")
coalition.addStaticObject(2, {
  name = "IR_RWY_001__I2", type = IR_RUNWAY.beacon_type, x = 30, y = 0,
})
advance(124.6)
assert(live == 46, "a replacement source must get a new spot")
IR_RUNWAY.shutdown()
assert(live == 0 and next(jobs) == nil, "shutdown must remove spots and timers")
flags[9001], flags[9002], flags[9003] = 0, 0, 0
local beforeReads, beforeCreates = flagReads, created
dofile("IR_Strobe_Beacons.lua")
advance(125.6)
assert(flagReads - beforeReads == 12, "false flag values must also be shared")
assert(created == beforeCreates and not IR_RUNWAY.pulse_timer)
IR_RUNWAY.shutdown()
assert(live == 0 and next(jobs) == nil and duplicateDestroys == 0)
print("OK: 285 creations in 120s; permanent mode, health opt-in, flags, replacement, reload, shutdown")
