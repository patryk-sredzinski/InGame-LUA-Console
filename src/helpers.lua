-- Small GUI / sprite helpers used across the mod.

local C = require("src.constants")

local M = {}

function M.add(parent, spec)
  local ok, result = pcall(function() return parent.add(spec) end)
  if ok then return result end
  spec.style = nil
  return parent.add(spec)
end

function M.pick_sprite(...)
  for _, path in ipairs({ ... }) do
    if helpers.is_valid_sprite_path(path) then return path end
  end
end

function M.set_mono(element)
  pcall(function() element.style.font = "default-mono" end)
end

function M.style_btn(el, width)
  el.style.height = C.BTN_H
  el.style.padding = 0
  el.style.minimal_height = C.BTN_H
  if width then el.style.width = width end
end

function M.play(player, path)
  pcall(function() player.play_sound { path = path } end)
end

function M.icon_sprite(icon)
  if icon and icon.name then
    local t = icon.type or "item"
    if t == "virtual" then t = "virtual-signal" end
    -- Prefer quality-aware sprite when Factorio exposes one.
    if type(icon.quality) == "string" and icon.quality ~= "" then
      local qpath = t .. "/" .. icon.name .. "/" .. icon.quality
      if helpers.is_valid_sprite_path(qpath) then return qpath end
    end
    local path = t .. "/" .. icon.name
    if helpers.is_valid_sprite_path(path) then return path end
  end
  return "ilc-console"
end

function M.screen_size(player)
  local res, scale = player.display_resolution, player.display_scale
  return math.floor(res.width / scale), math.floor(res.height / scale)
end

return M
