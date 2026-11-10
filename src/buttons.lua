-- Mod-gui top button that opens the console.

local C = require("src.constants")
local H = require("src.helpers")

local has_mod_gui, mod_gui = pcall(require, "mod-gui")

local M = {}

-- Remove leftover inventory-relative button from older versions.
local function remove_legacy_inventory_button(player)
  local old = player.gui.relative[C.BTN_FRAME]
  if old then old.destroy() end
end

function M.ensure(player)
  remove_legacy_inventory_button(player)

  if not has_mod_gui then return end
  pcall(function()
    local flow = mod_gui.get_button_flow(player)
    if not flow[C.BTN_TOP] then
      H.add(flow, {
        type = "sprite-button", name = C.BTN_TOP, style = mod_gui.button_style,
        sprite = "ilc-console", tooltip = { "ilc.open-tooltip" },
      })
    end
  end)
end

function M.remove(player)
  remove_legacy_inventory_button(player)
  if not has_mod_gui then return end
  pcall(function()
    local top = mod_gui.get_button_flow(player)[C.BTN_TOP]
    if top then top.destroy() end
  end)
end

return M
