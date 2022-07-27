local autodeploy = {}


local _ctx = function()
  if global.autodeploy_data == nil then
    global.autodeploy_data = {}
    global.autodeploy_data.version = 1
    global.autodeploy_data.check_time = 100
    global.autodeploy_data.player_settings = {}
  end
  return global.autodeploy_data
end


local _deploy = function(player, capsule_name, capsules_to_deploy)
  if not (capsules_to_deploy > 0) then
    return false
  end

  capsules_to_deploy = math.min(10, capsules_to_deploy)

  local deployed = player.remove_item({name=capsule_name, count=capsules_to_deploy})
  for i = 1, deployed, 1 do
    local rad = (i/deployed + (game.tick%360)/360) * 2 * math.pi
    local x_offset = 10*math.cos(rad)
    local y_offset = 10*math.sin(rad)
    player.surface.create_entity({
      name=capsule_name,
      force=player.force,
      position=player.position,
      speed=10,
      source=player.character,
      target={player.position.x+x_offset, player.position.y+y_offset},
    })
  end
  return (deployed > 0)
end

local function floor(n, m)
  return (n-n%m)/m
end

local deploy_robots_for_player = function(player)
  if not player.character or _ctx().player_settings[player.name] == 0 or player.surface.find_nearest_enemy {position = player.position, max_distance = 20, force = player.force} == nil then
    return
  end

  local max_robots = game.forces.player.maximum_following_robot_count
  local to_deploy = max_robots - #player.character.following_robots

  if not _deploy(player, 'destroyer-capsule', floor(to_deploy, 5)) then
    _deploy(player, 'defender-capsule', floor(to_deploy, 1))
  end
end


--[ COMMANDS ]--

autodeploy.command_toggle = function(data)
  local player = game.players[data.player_index]
  local current_state = _ctx().player_settings[player.name] or 1
  local new_state = 1-current_state
  _ctx().player_settings[player.name] = new_state
  if new_state == 1 then
    player.print({"autodeploy.active"})
  else
    player.print({"autodeploy.inactive"})
  end
end


--[ UPDATE ]--

autodeploy.update = function()
  if game.ticks_played > 0 and game.ticks_played % _ctx().check_time == 0 then
    for _, player in pairs(game.connected_players) do
      deploy_robots_for_player(player)
    end
  end
end


return autodeploy
