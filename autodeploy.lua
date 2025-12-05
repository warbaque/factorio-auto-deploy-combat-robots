local autodeploy = {}

local _deploy = function(player, capsule_name, capsule_quality, capsules_to_deploy)
  if not (capsules_to_deploy > 0) then
    return false
  end

  capsules_to_deploy = math.min(storage.players[player.index].max_capsules, capsules_to_deploy)

  local deployed = player.remove_item({name=capsule_name, quality=capsule_quality, count=capsules_to_deploy})
  if deployed > 0 then
    player.force.get_item_production_statistics(player.surface).on_flow({name=capsule_name, quality=capsule_quality}, -deployed)
  end
  for i = 1, deployed, 1 do
    local rad = (i/deployed + (game.tick%360)/360) * 2 * math.pi
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

  if not storage.players[player.index] or not character or not storage.players[player.index].autodeploy or _enemy_count(player) < storage.players[player.index].enemy_threshold then
    return
  end

  local max_robots = game.forces.player.maximum_following_robot_count
  local to_deploy = max_robots - #character.following_robots

  local qualities = {"legendary", "epic", "rare", "uncommon", "normal"}
  local combat_bots = {
    {
      name = 'destroyer-capsule',
      per_capsule = 5,
    },
    {
      name = 'defender-capsule',
      per_capsule = 1,
    },
  }
  for _, bot in ipairs(combat_bots) do
    for _, quality in ipairs(qualities) do
      if _deploy(player, bot.name, quality, floor(to_deploy, bot.per_capsule)) then
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
  storage.players = storage.players or {}
  for i, player in (pairs(game.players)) do
    storage.players[i] = storage.players[i] or _config(player)
    player.set_shortcut_toggled("autodeploy-shortcut", storage.players[i].autodeploy)
  end
end

autodeploy.set_player_config = function(event)
  local config = _config(game.players[event.player_index])
  storage.players[event.player_index] = config
  game.players[event.player_index].set_shortcut_toggled("autodeploy-shortcut", config.autodeploy)
end


--[ COMMANDS ]--

local _on_off = function(value)
  if value then return {"description.autodeploy_enable"}
  else return {"description.autodeploy_disable"} end
end

autodeploy.toggle = function(event)
  local player = game.players[event.player_index]

  local status = not storage.players[event.player_index].autodeploy
  storage.players[event.player_index].autodeploy = status
  player.create_local_flying_text {
    position = player.position,
    text = _on_off(status)
  }
  player.set_shortcut_toggled("autodeploy-shortcut", status)
end


--[ UPDATE ]--

autodeploy.update = function()
  for _, player in pairs(game.connected_players) do
    deploy_robots_for_player(player)
  end
end


return autodeploy
