local autodeploy = require ("autodeploy")

script.on_nth_tick(100, autodeploy.update)

script.on_event(defines.events.on_lua_shortcut, function(event)
  if event.prototype_name == "autodeploy-shortcut" then
    autodeploy.toggle(event)
  end
end)
script.on_event("autodeploy-toggle", autodeploy.toggle)

commands.add_command('autodeploy', {"autodeploy.command-description"}, autodeploy.toggle)

script.on_init(autodeploy.init)
script.on_configuration_changed(autodeploy.init)

script.on_event(defines.events.on_player_created, autodeploy.set_player_config)
script.on_event(defines.events.on_runtime_mod_setting_changed, autodeploy.set_player_config)
