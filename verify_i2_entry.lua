-- Run: lua verify_i2_entry.lua "path/to/Mods/tech/USLANTCOM I2 Beacon"
local mod=assert(arg[1], 'pass the tech pack directory')
local units,models,textures={},{},{}
local environment={
    _=function(s)return s end,
    current_mod_path=mod,wsType_Static=5,wsType_Standing=9,
    add_surface_unit=function(t)units[#units+1]=t end,
    declare_plugin=function()end,plugin_done=function()end,
    mount_vfs_model_path=function(p)models[#models+1]=p end,
    mount_vfs_texture_path=function(p)textures[#textures+1]=p end,
}
environment.dofile=function(path)return assert(loadfile(path,'t',environment))()end
environment.dofile(mod..'/entry.lua')
assert(#units==1 and #models==1 and #textures==1)
local unit=units[1]
assert(unit.Name=='USLANTCOM_I2_BEACON' and unit.ShapeName==unit.Name)
assert(unit.category=='Fortification' and unit.Life==1)
assert(#unit.attribute==2 and unit.attribute[1]==5 and unit.attribute[2]==9,
    'must register as a static structure, not a ground vehicle')
assert(unit.chassis==nil and unit.WS==nil and unit.sensor==nil)
assert(unit.mapclasskey=='P0091000076')
local shape=assert(unit.shape_table_data and unit.shape_table_data[1])
assert(shape.file==unit.Name and shape.username==unit.Name)
assert(shape.classname=='lLandVehicle' and shape.positioning=='BYNORMAL' and shape.life==1)
local file=assert(io.open(models[1]..'/'..shape.file..'.edm','rb'));file:close()
print('OK: native static structure registration, model mount and EDM; no ground-vehicle template')
