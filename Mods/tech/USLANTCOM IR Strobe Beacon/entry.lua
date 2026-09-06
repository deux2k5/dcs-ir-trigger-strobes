declare_plugin("USLANTCOM IR Strobe Beacon", {
    installed = true,
    dirName = current_mod_path,
    displayName = _("USLANTCOM IR Strobe Beacon"),
    shortName = "USLANTCOM IR Strobe Beacon",
    developerName = _("USLANTCOM"),
    fileMenuName = _("USLANTCOM IR Strobe Beacon"),
    version = "1.0.3",
    state = "installed",
    info = _("Standalone IR strobe beacon static prop with optional mission IR strobe script."),
})

mount_vfs_model_path(current_mod_path .. "/Shapes")
mount_vfs_texture_path(current_mod_path .. "/Textures")
dofile(current_mod_path .. "/IR-Strobe-Beacon.lua")
plugin_done()
