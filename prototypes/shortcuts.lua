data:extend({
  {
    type = "shortcut",
    name = "autodeploy-shortcut",
    action = "lua",
    associated_control_input = "autodeploy-toggle",
    technology_to_unlock = "defender",
    toggleable = true,
    icon = {
      filename = "__base__/graphics/icons/defender.png",
      priority = "extra-high-no-scale",
      size = 64,
      scale = 1,
      flags = {
        "icon"
      }
    }
  }
})
