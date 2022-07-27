local autodeploy = require ("autodeploy")

script.on_event(defines.events.on_tick, autodeploy.update)
commands.add_command('autodeploy', {"autodeploy.command-description"}, autodeploy.command_toggle)
