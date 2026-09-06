declare_plugin("USLANTCOM I2 Beacon", {
    installed = true,
    dirName = current_mod_path,
    displayName = _("USLANTCOM I2 Beacon"),
    shortName = "USLANTCOM I2 Beacon",
    developerName = _("USLANTCOM"),
    fileMenuName = _("USLANTCOM I2 Beacon"),
    version = "1.0.2",
    state = "installed",
    info = _("Standalone I2 beacon static prop with optional mission IR strobe script."),
})

mount_vfs_model_path(current_mod_path .. "/Shapes")
mount_vfs_texture_path(current_mod_path .. "/Textures")
dofile(current_mod_path .. "/I2-Beacon.lua")
plugin_done()
