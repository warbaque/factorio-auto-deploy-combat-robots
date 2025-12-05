local autodeploy = {}

local _deploy = function(player, capsule_name, capsule_quality, capsules_to_deploy)
  if not (capsules_to_deploy > 0) then
    return false
  end

  local deployed = player.remove_item({name=capsule_name, quality=capsule_quality, count=capsules_to_deploy})
  if deployed > 0 then
    player.force.get_item_production_statistics(player.surface).on_flow({name=capsule_name, quality=capsule_quality}, -deployed)
  end

  local offset = math.random()
  for i = 1, deployed, 1 do
    local rad = (i/deployed + offset) * 2 * math.pi
    local x_offset = 10*math.cos(rad)
    local y_offset = 10*math.sin(rad)
    player.surface.create_entity({
      name=capsule_name,
      quality=capsule_quality,
      force=player.force,
      position=player.position,
      speed=10,
      source=player.character,
      target={player.position.x+x_offset, player.position.y+y_offset},
    })
  end
  return (deployed > 0)
end

local _enemy_count = function(player)
  local position = player.position
  if player.surface.find_nearest_enemy {
      position = position,
      max_distance = 20,
      force = player.force
    } == nil then return 0 end

  return player.surface.count_entities_filtered {
    position = position,
    radius = 20,
    force = game.forces.enemy
  }
end

local function floor(n, m)
  return (n-n%m)/m
end

local deploy_robots_for_player = function(player)
  local character = player.character
  local config = storage.player_config[player.index]

  if not config or not character or not config.autodeploy or _enemy_count(player) < config.enemy_threshold then
    return
  end

  local max_robots = game.forces.player.maximum_following_robot_count
  local to_deploy = max_robots - #character.following_robots

  local qualities = {"legendary", "epic", "rare", "uncommon", "normal"}
  local combat_bots = {
    {
      name = 'destroyer-capsule',
      per_capsule = 5,
      per_second = 2
    },
    {
      name = 'defender-capsule',
      per_capsule = 1,
      per_second = 4
    },
  }
  for _, bot in ipairs(combat_bots) do
    for _, quality in ipairs(qualities) do
      local group = math.ceil(storage.player_config[player.index].max_capsules * bot.per_second / 4)
      if _deploy(player, bot.name, quality, math.floor(math.min(to_deploy / bot.per_capsule, group))) then
        return
      end
    end
  end
end


-- [ INIT ] --

local _config = function(player)
  return {
    autodeploy = true,
    enemy_threshold = player.mod_settings["autodeploy-enemy-threshold"].value,
    max_capsules = player.mod_settings["autodeploy-capsules-max"].value
  }
end

autodeploy.init = function()
  storage.player_config = storage.player_config or {}
  for i, _ in pairs(game.players) do
    autodeploy.on_player_created({player_index = i})
  end
end

autodeploy.on_player_created = function(event)
  storage.player_config[event.player_index] = storage.player_config[event.player_index] or _config(game.players[event.player_index])
  game.players[event.player_index].set_shortcut_toggled("autodeploy-shortcut", storage.player_config[event.player_index].autodeploy)
end

autodeploy.on_runtime_mod_setting_changed = function(event)
  if event.setting_type == "runtime-per-user" and event.player_index ~= nil then
    local config = _config(game.players[event.player_index])
    config.autodeploy = storage.player_config[event.player_index].autodeploy
    storage.player_config[event.player_index] = config
  end
end


--[ COMMANDS ]--

autodeploy.toggle = function(event)
  local player = game.players[event.player_index]
  local status = not storage.player_config[event.player_index].autodeploy
  storage.player_config[event.player_index].autodeploy = status

  player.create_local_flying_text {
    position = player.position,
    text = status and {"description.autodeploy_enable"} or {"description.autodeploy_disable"},
    color = status and {r=0, g=1, b=0} or {r=1, g=0, b=0},
  }
  player.set_shortcut_toggled("autodeploy-shortcut", status)
end

autodeploy.on_lua_shortcut = function(event)
  if event.prototype_name == "autodeploy-shortcut" then
    autodeploy.toggle(event)
  end
end


--[ UPDATE ]--

autodeploy.update = function()
  for _, player in pairs(game.connected_players) do
    deploy_robots_for_player(player)
  end
end


return autodeploy
