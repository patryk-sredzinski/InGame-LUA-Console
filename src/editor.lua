-- Manual edit ↔ syntax-preview switching.

local C = require("src.constants")
local highlight = require("highlight")
local state = require("src.state")
local H = require("src.helpers")

local M = {}

local function sync_raw(g, st)
  if g.edit and g.edit.valid and g.edit.visible then
    st.raw = g.edit.text or ""
  end
end

local function update_mode_btn(g, mode)
  local btn = g.mode_btn
  if not (btn and btn.valid) then return end
  btn.visible = true
  if mode == "preview" then
    btn.caption = { "ilc.edit" }
    btn.tooltip = { "ilc.edit-tooltip" }
  else
    btn.caption = { "ilc.preview" }
    btn.tooltip = { "ilc.preview-tooltip" }
  end
end

local function has_modal(player)
  local screen = player.gui.screen
  return screen[C.SAVE_DLG] or screen[C.CONFIRM_DLG] or screen[C.IO_DLG] or screen[C.ERR_DLG]
end

local function claim_opened(player, g)
  if has_modal(player) then return end
  if g and g.frame and g.frame.valid then
    player.opened = g.frame
  end
end

local function split_raw_lines(code)
  local lines = {}
  for line in ((code or ""):gsub("\r", "") .. "\n"):gmatch("(.-)\n") do
    lines[#lines + 1] = line
  end
  if #lines == 0 then lines[1] = "" end
  return lines
end

local function add_line_label(g, caption)
  local lab = g.view.add { type = "label", caption = caption }
  lab.style.single_line = false
  lab.style.horizontally_stretchable = true
  H.set_mono(lab)
  return lab
end

local function fill_preview(g, code, error_line)
  if not (g.view and g.view.valid) then return end
  g.view.clear()
  g.label = nil

  local raw_lines = split_raw_lines(code)
  local highlighted = highlight.render_lines(code)
  local total = math.max(#raw_lines, #highlighted)
  local limit = math.min(total, C.PREVIEW_MAX_LINES)

  if error_line then
    error_line = math.max(1, math.min(error_line, total))
  end

  local show_error_separately = error_line and error_line > limit
  local error_label

  for i = 1, limit do
    local caption
    if error_line and i == error_line then
      caption = highlight.render_error_line(raw_lines[i] or "")
    else
      caption = highlighted[i] or ""
    end
    local lab = add_line_label(g, caption)
    if error_line and i == error_line then
      error_label = lab
    end
  end

  if total > limit then
    add_line_label(g, { "ilc.preview-truncated", total, C.PREVIEW_MAX_LINES })
  end

  if show_error_separately then
    error_label = add_line_label(g, highlight.render_error_line(raw_lines[error_line] or ""))
  end

  if error_label and error_label.valid then
    pcall(function() g.view.scroll_to_element(error_label) end)
  else
    pcall(function() g.view.scroll_to_top() end)
  end
end

function M.show_preview(player, error_line)
  local g, st = state.gui(player)
  if not g then return end
  sync_raw(g, st)

  st.error_line = error_line
  fill_preview(g, st.raw, error_line)
  g.edit.visible = false
  g.view.visible = true
  st.mode = "preview"
  update_mode_btn(g, "preview")
  claim_opened(player, g)
end

function M.show_edit(player)
  local g, st = state.gui(player)
  if not g then return end
  st.error_line = nil
  g.view.visible = false
  g.edit.visible = true
  g.edit.text = st.raw or ""
  st.mode = "edit"
  update_mode_btn(g, "edit")
  claim_opened(player, g)
  -- Only steal focus when the execute hotkey is off; otherwise shortcuts would die.
  if not st.hotkey_execute then
    g.edit.focus()
  elseif g.run and g.run.valid then
    pcall(function() g.run.focus() end)
  end
end

function M.toggle_mode(player)
  local st = state.player(player.index)
  if st.mode == "preview" then
    M.show_edit(player)
  else
    M.show_preview(player)
  end
end

return M
