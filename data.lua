data:extend({
  {
    type = "sprite",
    name = "ilc-console",
    filename = "__ingame-lua-console__/graphics/console.png",
    priority = "extra-high-no-scale",
    width = 64,
    height = 64,
    flags = { "gui-icon" },
  },
  {
    type = "custom-input",
    name = "ilc-toggle",
    key_sequence = "CONTROL + SHIFT + L",
    action = "lua",
    -- Allow rebinding in Settings → Controls; don't eat the key from the game world.
    consuming = "none",
  },
  {
    type = "custom-input",
    name = "ilc-execute",
    key_sequence = "CONTROL + RETURN",
    action = "lua",
    consuming = "none",
  },
})
