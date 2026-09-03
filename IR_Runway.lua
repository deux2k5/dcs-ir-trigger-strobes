-- One IR strobe at the center of every trigger zone named IR_STROBE_...
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
  country = "USA",
  static_type = "Invisible FARP",
  shape_name = "invisiblefarp",
  source_name = "IR_RUNWAY_SOURCE",
  active = false,
  spots = {},
}

local R = IR_RUNWAY

local function collectPoints(zones, getZone)
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

local function clearSpots()
  for _, spot in ipairs(R.spots) do
    pcall(function() spot:destroy() end)
  end
  R.spots = {}
  R.off_timer = nil
end

local function getSource()
  if R.source and R.source:isExist() then return R.source end

  local unitName = R.source_name .. "-1"
  local source = StaticObject.getByName(unitName)
  if source and source:isExist() then
    R.source = source
    return source
  end

  local countryId = country.id[R.country]
  if not countryId then
    report("unknown country " .. R.country)
    return nil
  end

  local point = R.source_point
  local data = {
    name = R.source_name,
    visible = false,
    hidden = true,
    dead = false,
    x = point.x,
    y = point.y,
    units = {{
      name = unitName,
      category = "Heliports",
      type = R.static_type,
      shape_name = R.shape_name,
      heliport_callsign_id = 1,
      heliport_frequency = 127.5,
      heliport_modulation = 0,
      rate = 100,
      x = point.x,
      y = point.y,
      heading = 0,
    }},
  }

  local ok
  ok, source = pcall(coalition.addGroup, countryId, -1, data)
  if not ok or not source then
    report("could not create Invisible FARP source")
    return nil
  end
  R.source = StaticObject.getByName(unitName) or source
  return R.source
end

local function flash(_, now)
  if not R.active then return nil end

  local source = R.source
  if not source or not source:isExist() then
    R.active = false
    R.pulse_timer = nil
    return nil
  end

  clearSpots()
  local position = source:getPosition()
  for _, marker in ipairs(R.points) do
    if marker.enabled then
      refreshPoint(marker, trigger.misc.getZone)
      local height = land.getHeight({ x = marker.x, y = marker.y })
      local origin = { x = marker.x, y = height + 2, z = marker.y }
      local ok, spot = pcall(
        Spot.createInfraRed,
        source,
        worldToLocal(position, origin),
        { x = marker.x, y = height + 1, z = marker.y }
      )
      if ok and spot then R.spots[#R.spots + 1] = spot end
    end
  end

  R.off_timer = timer.scheduleFunction(function() clearSpots() end, nil, now + R.flash_seconds)
  return now + R.period_seconds
end

function R.start()
  if R.active then return true end
  if not getSource() then return false end
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

  if anyEnabled and not R.active and not R.start_failed then
    R.start_failed = not R.start()
  elseif not anyEnabled then
    R.start_failed = false
    if R.active then R.stop() end
  end
  return now + 0.25
end

local function init()
  local points = collectPoints(env.mission.triggers.zones, trigger.misc.getZone)
  if #points == 0 then
    report("no zones named " .. R.zone_prefix .. "<flag>")
    return
  end

  R.points = points
  R.source_point = { x = points[1].x, y = points[1].y }
  if env and env.info then
    env.info(string.format("[IR STROBES] ready: %d individually controlled zones", #points))
  end
  R.watch_timer = timer.scheduleFunction(watchFlags, nil, timer.getTime() + 0.1)
end

local function selfTest()
  local fakeZones = {
    { name = "IR_STROBE_9003" },
    { name = "NOT_A_STROBE" },
    { name = "IR_STROBE_BAD" },
    { name = "IR_STROBE_9002" },
  }
  local points = collectPoints(fakeZones, function(name)
    if name == "IR_STROBE_9002" then return { point = { x = 10, z = 20 } } end
    return { point = { x = 30, z = 40 } }
  end)
  assert(#points == 2 and points[1].name == "IR_STROBE_9002")
  assert(points[1].flag == 9002 and points[1].x == 10 and points[1].y == 20)
  refreshPoint(points[1], function() return { point = { x = 50, z = 60 } } end)
  assert(points[1].x == 50 and points[1].y == 60)
  assert(R.static_type == "Invisible FARP")
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
  and rawget(_G, "StaticObject") and rawget(_G, "land") then
  init()
else
  selfTest()
end
