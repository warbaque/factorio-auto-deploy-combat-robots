local autodeploy = require("autodeploy")

script.on_init(autodeploy.init)
script.on_configuration_changed(autodeploy.init)
script.on_nth_tick(100, autodeploy.update)
script.on_event(defines.events.on_player_created, autodeploy.on_player_created)
script.on_event(defines.events.on_runtime_mod_setting_changed, autodeploy.on_runtime_mod_setting_changed)

script.on_event(defines.events.on_lua_shortcut, autodeploy.on_lua_shortcut)
script.on_event("autodeploy-toggle", autodeploy.toggle)
commands.add_command("autodeploy", {"autodeploy.command-description"}, autodeploy.toggle)