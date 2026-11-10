-- Script library persistence (map `storage`).

local C = require("src.constants")
local state = require("src.state")

local M = {}

function M.sanitize_icon(icon)
  if type(icon) ~= "table" then return nil end
  if type(icon.name) ~= "string" or icon.name == "" then return nil end
  local t = icon.type
  if type(t) ~= "string" or t == "" then t = "item" end
  local out = { type = t, name = icon.name }
  if type(icon.quality) == "string" and icon.quality ~= "" then
    out.quality = icon.quality
  end
  return out
end

function M.parse(raw)
  if type(raw) ~= "string" or raw == "" then return nil end
  if #raw > C.IMPORT_MAX_RAW then return nil end

  local ok, data = pcall(helpers.json_to_table, raw)
  if not (ok and type(data) == "table" and type(data.scripts) == "table") then return nil end

  local max = 0
  local next_id = data.next_id
  if type(next_id) ~= "number" then next_id = 1 end

  for _, s in ipairs(data.scripts) do
    if type(s) == "table" and type(s.id) == "number" and s.id > max then
      max = s.id
    end
  end
  data.next_id = math.max(next_id, max + 1)
  return data
end

local function is_library_data(data)
  return type(data) == "table" and type(data.scripts) == "table"
end

function M.load(player)
  local library = state.store().library
  local key = player.index
  local data = library[key]
  if is_library_data(data) then return data end

  -- Migrate legacy name-keyed libraries from older versions.
  local legacy = library[player.name]
  if is_library_data(legacy) then
    library[key] = legacy
    library[player.name] = nil
    return legacy
  end

  data = { version = 1, next_id = 1, scripts = {} }
  library[key] = data
  return data
end

function M.persist(player, data)
  state.store().library[player.index] = data
end

function M.remove(player_index)
  local store = state.store()
  if store.players then store.players[player_index] = nil end
  if store.library then store.library[player_index] = nil end
end

function M.migrate_all()
  for _, player in pairs(game.players) do
    M.load(player)
  end
end

function M.find(data, id)
  for _, s in ipairs(data.scripts) do
    if s.id == id then return s end
  end
end

return M
