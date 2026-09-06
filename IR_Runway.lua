-- USLANTCOM tech asset pack I2 integration of https://github.com/deux2k5/dcs-ir-trigger-strobes
-- All IR_STROBE_<flag> zones spawn an I2 beacon; placed I2 objects with
-- the same naming convention work without zones (use the UNIT/object name).
-- Load once with MISSION START -> DO SCRIPT FILE.
-- The number in each zone name is its flag: IR_STROBE_9002 uses flag 9002.
-- Zone radius is ignored; place and name each zone manually.
-- Link a zone to a moving unit in the Mission Editor to make its strobe follow.

if IR_RUNWAY and IR_RUNWAY.shutdown then
  pcall(IR_RUNWAY.shutdown)
end

IR_RUNWAY = {
  zone_prefix = "IR_STROBE_",
  flash_seconds = 0.5,
  period_seconds = 1,
  mount_clearance = 1,
  country = "USA",
  beacon_type = "USLANTCOM_I2_BEACON",
  beacon_height = 0.032, -- meters: export origin is under the beacon head
  ir_clearance = 0.01, -- IR target just above the housing; tune in DCS if needed
  active = false,
  spots = {},
}

local R = IR_RUNWAY

local function findUnitName(node, id)
  if type(node) ~= "table" then return nil end
  if node.unitId == id then return node.name end
  for _, child in pairs(node) do
    local name = findUnitName(child, id)
    if name then return name end
  end
end

local function collectPoints(zones, getZone, units)
  local points = {}
  for _, zone in pairs(zones or {}) do
    local name = zone.name
    local flag = type(name) == "string" and name:match("^" .. R.zone_prefix .. "(%d+)$")
    if flag then
      local liveZone = getZone(name)
      if liveZone then
        points[#points + 1] = {
          name = name,
          flag = tonumber(flag),
          x = liveZone.point.x,
          y = liveZone.point.z,
          unit_name = zone.linkUnit and findUnitName(units, zone.linkUnit),
          linked = zone.linkUnit ~= nil,
        }
      end
    end
  end
  table.sort(points, function(a, b) return a.name < b.name end)
  return points
end

local function refreshPoint(marker, getZone)
  local zone = getZone(marker.name)
  if zone then marker.x, marker.y = zone.point.x, zone.point.z end
end

local function mountedHeight(marker, getUnit)
  local unit = marker.unit_name and getUnit(marker.unit_name)
  if not unit or not unit:isExist() then return nil end
  local desc = unit:getDesc()
  local box = desc and desc.box
  if not box then return nil end
  return unit:getPoint().y + box.max.y + math.abs(box.min.y) + R.mount_clearance
end

local function report(message)
  if env and env.error then env.error("[IR STROBES] " .. message) end
  if trigger and trigger.action then trigger.action.outText("IR strobes: " .. message, 15) end
end

local function worldToLocal(position, point)
  local dx = point.x - position.p.x
  local dy = point.y - position.p.y
  local dz = point.z - position.p.z
  return {
    x = dx * position.x.x + dy * position.x.y + dz * position.x.z,
    y = dx * position.y.x + dy * position.y.y + dz * position.y.z,
    z = dx * position.z.x + dy * position.z.y + dz * position.z.z,
  }
end

local function alive(object)
  return object and object:isExist() and object:getLife() > 0
end

local function getObject(name)
  return StaticObject.getByName(name) or Unit.getByName(name)
end

local function collectBeacons(node, points)
  if type(node) ~= "table" then return end
  local flag = type(node.name) == "string" and node.name:match("^" .. R.zone_prefix .. "(%d+)$")
  if node.type == R.beacon_type and flag then
    local marker
    for _, point in ipairs(points) do
      if point.name == node.name then marker = point; break end
    end
    if not marker then
      marker = { name = node.name, flag = tonumber(flag), x = node.x, y = node.y }
      points[#points + 1] = marker
    end
    -- A named, placed beacon takes precedence over a same-named zone.
    marker.beacon_name = node.name
    marker.linked, marker.unit_name = false, nil
  else
    for _, child in pairs(node) do collectBeacons(child, points) end
  end
end

local function prepareBeacon(marker)
  if marker.beacon_name then return end
  local name = marker.name .. "__I2"
  marker.beacon_name = name
  local existing = getObject(name)
  if existing then
    if existing:getTypeName() ~= R.beacon_type then
      report("name already in use; not replacing " .. name)
      marker.failed = true
    end
    return -- Reuse existing props and wrecks on script reload.
  end
  local countryId = country.id[R.country]
  local ok, object = false, nil
  if countryId then
    ok, object = pcall(coalition.addStaticObject, countryId, {
      name = name, type = R.beacon_type, shape_name = R.beacon_type,
      category = "Fortifications", x = marker.x, y = marker.y,
      heading = 0, dead = false, rate = 1,
    })
  end
  if not ok or not object then
    marker.failed = true
    report("could not spawn " .. name .. "; check USLANTCOM tech asset pack installation and country")
  end
end

local function targetPoint(marker, beacon)
  if marker.linked then
    if not alive(marker.unit_name and Unit.getByName(marker.unit_name)) then return nil end
    refreshPoint(marker, trigger.misc.getZone)
    local height = land.getHeight({ x = marker.x, y = marker.y })
    local originY = mountedHeight(marker, Unit.getByName) or height + 2
    return { x = marker.x, y = originY - 1, z = marker.y }
  end
  local position = beacon:getPosition()
  local height = R.beacon_height + R.ir_clearance
  return {
    x = position.p.x + position.y.x * height,
    y = position.p.y + position.y.y * height,
    z = position.p.z + position.y.z * height,
  }
end

local function clearSpots()
  for _, spot in ipairs(R.spots) do
    pcall(function() spot:destroy() end)
  end
  R.spots = {}
  R.off_timer = nil
end

local function flash(_, now)
  if not R.active then return nil end

  clearSpots()
  for _, marker in ipairs(R.points) do
    local source = marker.enabled and not marker.failed and getObject(marker.beacon_name)
    local target = alive(source) and source:getTypeName() == R.beacon_type and targetPoint(marker, source)
    if target then
      local position = source:getPosition()
      -- Each I2 is its own IR source. Linked zones retain a virtual moving offset.
      local origin = { x = target.x, y = target.y + 1, z = target.z }
      local ok, spot = pcall(
        Spot.createInfraRed,
        source,
        worldToLocal(position, origin),
        target
      )
      if ok and spot then
        R.spots[#R.spots + 1] = spot
      elseif not marker.spot_error then
        marker.spot_error = true
        report("could not create IR spot for " .. marker.name)
      end
    end
  end

  R.off_timer = timer.scheduleFunction(function() clearSpots() end, nil, now + R.flash_seconds)
  return now + R.period_seconds
end

function R.start()
  if R.active then return true end
  R.active = true
  R.pulse_timer = timer.scheduleFunction(flash, nil, timer.getTime() + 0.01)
  return true
end

function R.stop()
  R.active = false
  if R.pulse_timer then pcall(timer.removeFunction, R.pulse_timer) end
  if R.off_timer then pcall(timer.removeFunction, R.off_timer) end
  R.pulse_timer, R.off_timer = nil, nil
  clearSpots()
end

function R.shutdown()
  R.stop()
  if R.watch_timer then pcall(timer.removeFunction, R.watch_timer) end
  R.watch_timer = nil
end

local function watchFlags(_, now)
  local anyEnabled = false
  for _, marker in ipairs(R.points) do
    marker.enabled = (tonumber(trigger.misc.getUserFlag(marker.flag)) or 0) ~= 0
    anyEnabled = anyEnabled or marker.enabled
  end

  if anyEnabled and not R.active then
    R.start()
  elseif not anyEnabled and R.active then
    R.stop()
  end
  return now + 0.25
end

local function init()
  local points = collectPoints((env.mission.triggers or {}).zones, trigger.misc.getZone, env.mission.coalition)
  collectBeacons(env.mission.coalition, points)
  if #points == 0 then
    report("no zones or I2 beacons named " .. R.zone_prefix .. "<flag>")
    return
  end

  R.points = points
  for _, marker in ipairs(points) do prepareBeacon(marker) end
  if env and env.info then
    env.info(string.format("[IR STROBES] ready: %d individually controlled markers", #points))
  end
  R.watch_timer = timer.scheduleFunction(watchFlags, nil, timer.getTime() + 0.1)
end

local function selfTest()
  local fakeZones = {
    { name = "IR_STROBE_9003" },
    { name = "NOT_A_STROBE" },
    { name = "IR_STROBE_BAD" },
    { name = "IR_STROBE_9002", linkUnit = 42 },
  }
  local points = collectPoints(fakeZones, function(name)
    if name == "IR_STROBE_9002" then return { point = { x = 10, z = 20 } } end
    return { point = { x = 30, z = 40 } }
  end, { units = {{ unitId = 42, name = "Test Truck" }} })
  assert(#points == 2 and points[1].name == "IR_STROBE_9002")
  assert(points[1].flag == 9002 and points[1].x == 10 and points[1].y == 20)
  assert(points[1].unit_name == "Test Truck")
  refreshPoint(points[1], function() return { point = { x = 50, z = 60 } } end)
  assert(points[1].x == 50 and points[1].y == 60)
  assert(mountedHeight(points[1], function()
    return {
      isExist = function() return true end,
      getDesc = function() return { box = { min = { y = -0.5 }, max = { y = 1.5 } } } end,
      getPoint = function() return { y = 100 } end,
    }
  end) == 103)
  assert(R.beacon_type == "USLANTCOM_I2_BEACON")
  local localPoint = worldToLocal(
    {
      p = { x = 10, y = 20, z = 30 },
      x = { x = 1, y = 0, z = 0 },
      y = { x = 0, y = 1, z = 0 },
      z = { x = 0, y = 0, z = 1 },
    },
    { x = 13, y = 25, z = 37 }
  )
  assert(localPoint.x == 3 and localPoint.y == 5 and localPoint.z == 7)
  print("OK: IR_STROBE_9002 is controlled by flag 9002")
end

if rawget(_G, "trigger") and rawget(_G, "timer") and rawget(_G, "Spot")
  and rawget(_G, "StaticObject") and rawget(_G, "Unit") and rawget(_G, "land") then
  init()
else
  selfTest()
end
