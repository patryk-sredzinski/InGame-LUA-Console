-- Save / load / delete / new script actions.

local state = require("src.state")
local library = require("src.library")
local dialogs = require("src.dialogs")
local console = require("src.console")
local script_list = require("src.script_list")
local H = require("src.helpers")

local M = {}

function M.save(player)
  local st = state.player(player.index)
  local d = st.dialog
  if not (d and d.title and d.title.valid) then return end

  local g = st.gui
  if g and g.edit and g.edit.valid and g.edit.visible then
    st.raw = g.edit.text or st.raw
  end

  local title = d.title.text:match("^%s*(.-)%s*$")
  if title == "" then title = "Untitled" end

  local value = d.icon.valid and d.icon.elem_value or nil
  local icon = library.sanitize_icon(value)

  local data = library.load(player)
  local entry = st.current_id and library.find(data, st.current_id) or nil
  -- Same title → overwrite. Renamed → save as a new script.
  if entry and entry.title == title then
    entry.icon, entry.code = icon, st.raw
  else
    entry = { id = data.next_id, title = title, icon = icon, code = st.raw }
    data.next_id = data.next_id + 1
    data.scripts[#data.scripts + 1] = entry
  end
  st.current_id = entry.id

  library.persist(player, data)
  dialogs.close(player)
  script_list.rebuild(player)
  H.play(player, "utility/confirm")
end

function M.delete(player, id)
  local data = library.load(player)
  for i, s in ipairs(data.scripts) do
    if s.id == id then
      table.remove(data.scripts, i)
      break
    end
  end
  library.persist(player, data)
  local st = state.player(player.index)
  if st.current_id == id then st.current_id = nil end
  dialogs.close(player)
  script_list.rebuild(player)
end

function M.load(player, id)
  local entry = id and library.find(library.load(player), id)
  if not entry then return end
  local g = state.gui(player)
  if not g then return end
  state.player(player.index).current_id = entry.id
  script_list.rebuild(player)
  console.set_text(player, entry.code or "", "preview")
end

function M.new(player)
  local g = state.gui(player)
  if not g then return end
  state.player(player.index).current_id = nil
  script_list.rebuild(player)
  console.set_text(player, "", "edit")
end

return M
