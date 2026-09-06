-- Native static structure, matching ED's static drop-zone marker registration.
-- A ground-vehicle template is not a substitute for a static object definition.
local beacon = {
    Name = "USLANTCOM_I2_BEACON",
    DisplayName = _("IR Strobe Beacon - USLANTCOM"),
    ShapeName = "USLANTCOM_I2_BEACON",
    Life = 1,
    Rate = 1,
    category = "Fortification",
    SeaObject = false,
    isPutToWater = false,
    mapclasskey = "P0091000076",
    attribute = {wsType_Static, wsType_Standing},
}
beacon.shape_table_data = {{
    file = beacon.ShapeName,
    username = beacon.Name,
    desrt = "self",
    classname = "lLandVehicle",
    positioning = "BYNORMAL",
    life = beacon.Life,
}}
add_surface_unit(beacon)
