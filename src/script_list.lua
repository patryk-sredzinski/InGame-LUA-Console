-- Rebuilds the saved-scripts sidebar list.

local C = require("src.constants")
local H = require("src.helpers")
local state = require("src.state")
local library = require("src.library")

local M = {}

local function matches(entry, query)
  if not query or query == "" then return true end
  local title = tostring(entry.title or ""):lower()
  return title:find(query, 1, true) ~= nil
end

function M.rebuild(player)
  local g, st = state.gui(player)
  if not g or not g.list or not g.list.valid then return end
  local list = g.list
  list.clear()

  local data = library.load(player)
  if #data.scripts == 0 then
    list.add { type = "label", caption = { "ilc.no-scripts" } }
    return
  end

  local query = (st.search or ""):lower():match("^%s*(.-)%s*$") or ""
  local shown = 0
  for _, entry in ipairs(data.scripts) do
    if matches(entry, query) then
      shown = shown + 1
      local row = list.add { type = "flow", direction = "horizontal" }
      row.style.vertical_align = "center"
      row.style.horizontal_spacing = C.PAD
      row.style.padding = 0
      row.style.horizontally_stretchable = true

      local icon = H.add(row, {
        type = "sprite-button", name = C.LOAD_ICON, style = "tool_button",
        sprite = H.icon_sprite(entry.icon), tooltip = entry.title, tags = { id = entry.id },
      })
      H.style_btn(icon, C.BTN_H)

      -- Fill remaining width so X lines up with search / New right edge.
      local content_w = C.SIDE_W - C.PAD * 2
      local title_w = content_w - C.BTN_H - C.PAD - C.PAD - C.BTN_H

      local selected = st.current_id == entry.id
      local title = H.add(row, {
        type = "button", name = C.LOAD, style = selected and "confirm_button" or "button",
        caption = entry.title, tooltip = entry.title, tags = { id = entry.id },
      })
      H.style_btn(title, title_w)
      title.style.horizontal_align = "left"
      title.style.horizontally_stretchable = true

      local del = H.add(row, {
        type = "button", name = C.DELETE, style = "red_button",
        caption = "X", tooltip = { "ilc.delete-tooltip" }, tags = { id = entry.id },
      })
      H.style_btn(del, C.BTN_H)
    end
  end

  if shown == 0 then
    list.add { type = "label", caption = { "ilc.no-matching-scripts" } }
  end
end

return M
