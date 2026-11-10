-- Main console window: open / close / layout / minimize.

local C = require("src.constants")
local H = require("src.helpers")
local state = require("src.state")
local editor = require("src.editor")
local script_list = require("src.script_list")
local dialogs = require("src.dialogs")

local M = {}

function M.close(player)
  dialogs.close(player)
  local st = state.player(player.index)
  local g = st.gui
  -- Keep last editor text so the execute hotkey still works with the console closed.
  if g and g.edit and g.edit.valid then
    st.raw = g.edit.text or st.raw
  end
  local el = player.gui.screen[C.MAIN]
  if el then el.destroy() end
  st.gui = nil
end

local function code_size(player, minimized)
  local sw, sh = H.screen_size(player)
  if minimized then
    local code_w = math.max(math.floor(sw * 0.70 * 0.5) - 24, 280)
    local code_h = math.max(math.floor(sh * 0.75 * 0.5) - 90, 140)
    return code_w, code_h
  end
  local win_w = math.floor(sw * 0.70)
  local win_h = math.floor(sh * 0.75)
  local code_w = math.max(win_w - C.SIDE_W - 36, 320)
  local code_h = math.max(win_h - 110, 220)
  return code_w, code_h
end

local function update_minmax_button(btn, minimized)
  if not (btn and btn.valid) then return end
  if minimized then
    local sprite = H.pick_sprite("utility/expand", "utility/expand_dark", "utility/enter")
    if sprite then
      btn.sprite = sprite
      btn.hovered_sprite = H.pick_sprite("utility/expand_dark", sprite)
      btn.clicked_sprite = H.pick_sprite("utility/expand_dark", sprite)
    end
    btn.tooltip = { "ilc.maximize" }
  else
    local sprite = H.pick_sprite("utility/collapse", "utility/collapse_dark", "utility/reset")
    if sprite then
      btn.sprite = sprite
      btn.hovered_sprite = H.pick_sprite("utility/collapse_dark", sprite)
      btn.clicked_sprite = H.pick_sprite("utility/collapse_dark", sprite)
    end
    btn.tooltip = { "ilc.minimize" }
  end
end

function M.apply_layout(player)
  local g, st = state.gui(player)
  if not g then return end
  local minimized = st.minimized
  local code_w, code_h = code_size(player, minimized)
  local col_h = code_h + C.BTN_H + C.PAD * 3

  g.edit.style.width = code_w
  g.edit.style.height = code_h
  g.view.style.width = code_w
  g.view.style.height = code_h
  if g.view and g.view.valid then
    for _, child in pairs(g.view.children) do
      if child.valid and child.type == "label" then
        child.style.maximal_width = code_w - C.PAD * 2
      end
    end
  end

  if g.right and g.right.valid then
    g.right.style.height = col_h
  end

  if g.left and g.left.valid then
    g.left.visible = not minimized
    if not minimized then
      g.left.style.width = C.SIDE_W
      g.left.style.height = col_h
    end
  end
  if g.search and g.search.valid then
    g.search.style.width = C.SIDE_W - C.PAD * 2
  end

  update_minmax_button(g.minmax, minimized)
  g.frame.bring_to_front()
end

local function has_modal(player)
  local screen = player.gui.screen
  return screen[C.SAVE_DLG] or screen[C.CONFIRM_DLG] or screen[C.IO_DLG] or screen[C.ERR_DLG]
end

-- Make Escape close the console (player.opened = main frame).
function M.claim_opened(player)
  local g = state.gui(player)
  if not g or has_modal(player) then return end
  player.opened = g.frame
end

function M.focus(player)
  local g, st = state.gui(player)
  if not g or has_modal(player) then return end
  M.claim_opened(player)
  if st.mode == "edit" and g.edit and g.edit.valid then
    g.edit.focus()
  end
end

-- Factorio blocks all custom-inputs while a text-box has focus.
-- Park focus on Execute so the run hotkey can fire.
function M.release_editor_focus(player)
  local g = state.gui(player)
  if not g or has_modal(player) then return end
  M.claim_opened(player)
  if g.run and g.run.valid then
    pcall(function() g.run.focus() end)
  end
end

function M.set_text(player, text, mode)
  local g, st = state.gui(player)
  if not g then return end
  st.raw = text or ""
  g.edit.text = st.raw
  if mode == "preview" then
    editor.show_preview(player)
  else
    editor.show_edit(player)
  end
end

function M.open(player)
  M.close(player)
  local st = state.player(player.index)

  local frame = H.add(player.gui.screen, { type = "frame", name = C.MAIN, direction = "vertical" })
  frame.auto_center = true
  frame.style.padding = C.PAD

  local bar = frame.add { type = "flow", name = "ilc_titlebar", direction = "horizontal" }
  bar.drag_target = frame
  bar.style.horizontal_spacing = C.PAD
  bar.style.vertical_align = "center"
  H.add(bar, { type = "label", style = "frame_title", caption = { "ilc.title" }, ignored_by_interaction = true })
  local drag = H.add(bar, { type = "empty-widget", style = "draggable_space_header", ignored_by_interaction = true })
  drag.style.horizontally_stretchable = true
  drag.style.height = 24
  drag.style.right_margin = 4

  local minmax
  local collapse_sprite = H.pick_sprite("utility/collapse", "utility/collapse_dark", "utility/reset")
  if collapse_sprite then
    minmax = H.add(bar, {
      type = "sprite-button", name = C.MINMAX, style = "frame_action_button",
      sprite = collapse_sprite,
      hovered_sprite = H.pick_sprite("utility/collapse_dark", collapse_sprite),
      clicked_sprite = H.pick_sprite("utility/collapse_dark", collapse_sprite),
      tooltip = { "ilc.minimize" },
    })
  else
    minmax = H.add(bar, { type = "button", name = C.MINMAX, caption = "-", tooltip = { "ilc.minimize" } })
    H.style_btn(minmax, C.BTN_H)
  end

  local close_sprite = H.pick_sprite("utility/close", "utility/close_white")
  if close_sprite then
    H.add(bar, {
      type = "sprite-button", name = C.CLOSE, style = "frame_action_button", sprite = close_sprite,
      hovered_sprite = H.pick_sprite("utility/close_black", close_sprite),
      clicked_sprite = H.pick_sprite("utility/close_black", close_sprite),
      tooltip = { "ilc.close" },
    })
  else
    local c = H.add(bar, { type = "button", name = C.CLOSE, caption = "X", tooltip = { "ilc.close" } })
    H.style_btn(c, C.BTN_H)
  end

  local body = frame.add { type = "flow", name = "ilc_body", direction = "horizontal" }
  body.style.horizontally_stretchable = true
  body.style.vertically_stretchable = true
  body.style.horizontal_spacing = C.PAD

  local left = H.add(body, { type = "frame", name = "ilc_left", style = "inside_shallow_frame", direction = "vertical" })
  left.style.padding = C.PAD
  local left_col = left.add { type = "flow", name = "ilc_left_col", direction = "vertical" }
  left_col.style.vertical_spacing = C.PAD
  left_col.style.vertically_stretchable = true
  left_col.style.horizontally_stretchable = true

  local head = left_col.add { type = "flow", name = "ilc_left_head", direction = "horizontal" }
  head.style.vertical_align = "center"
  head.style.horizontal_spacing = C.PAD
  head.style.height = C.BTN_H
  H.add(head, { type = "label", style = "caption_label", caption = { "ilc.saved-scripts" } })
  local head_fill = head.add { type = "empty-widget" }
  head_fill.style.horizontally_stretchable = true
  local new_btn = H.add(head, { type = "button", name = C.NEW, caption = { "ilc.new" }, tooltip = { "ilc.new-tooltip" } })
  H.style_btn(new_btn, 64)

  -- Factorio textfields have no placeholder API; use tooltip instead.
  local search = left_col.add {
    type = "textfield", name = C.SEARCH, text = st.search or "",
    tooltip = { "ilc.search-placeholder" },
  }
  search.style.horizontally_stretchable = true
  search.style.width = C.SIDE_W - C.PAD * 2
  search.style.height = C.BTN_H

  local list = H.add(left_col, { type = "scroll-pane", name = C.LIST, horizontal_scroll_policy = "never" })
  list.style.vertically_stretchable = true
  list.style.horizontally_stretchable = true
  list.style.padding = 0

  local io_btn = H.add(left_col, { type = "button", name = C.IO_BTN, caption = { "ilc.io-button" } })
  H.style_btn(io_btn)
  io_btn.style.horizontally_stretchable = true

  local right = H.add(body, { type = "frame", name = "ilc_right", style = "inside_shallow_frame", direction = "vertical" })
  right.style.padding = C.PAD
  right.style.horizontally_stretchable = true
  local right_col = right.add { type = "flow", name = "ilc_right_col", direction = "vertical" }
  right_col.style.vertical_spacing = C.PAD
  right_col.style.vertically_stretchable = true
  right_col.style.horizontally_stretchable = true

  local edit = right_col.add { type = "text-box", name = C.EDIT, text = st.raw }
  edit.word_wrap = false
  H.set_mono(edit)
  pcall(function() edit.rich_text_setting = defines.rich_text_setting.disabled end)

  local view = H.add(right_col, { type = "scroll-pane", name = C.VIEW, style = "text_holding_scroll_pane" })
  view.visible = false
  view.horizontal_scroll_policy = "never"
  view.vertical_scroll_policy = "auto"
  local label = view.add { type = "label", name = C.VIEW_LABEL, caption = "" }
  label.style.single_line = false
  label.style.horizontally_stretchable = true
  H.set_mono(label)

  local bottom = right_col.add { type = "flow", name = "ilc_bar", direction = "horizontal" }
  bottom.style.vertical_align = "center"
  bottom.style.horizontal_spacing = C.PAD
  bottom.style.height = C.BTN_H

  local save = H.add(bottom, { type = "button", name = C.SAVE, caption = { "ilc.save" } })
  H.style_btn(save, 80)

  bottom.add {
    type = "checkbox",
    name = C.HOTKEY_EXECUTE,
    state = st.hotkey_execute and true or false,
    caption = { "ilc.hotkey-execute" },
    tooltip = { "ilc.hotkey-execute-tooltip" },
  }

  local bottom_fill = bottom.add { type = "empty-widget" }
  bottom_fill.style.horizontally_stretchable = true

  -- Always-visible toggle: Preview in edit mode, Edit in preview mode.
  local mode_btn = H.add(bottom, {
    type = "button", name = C.MODE_BTN, caption = { "ilc.preview" }, tooltip = { "ilc.preview-tooltip" },
  })
  H.style_btn(mode_btn, 90)

  local validate = H.add(bottom, {
    type = "button", name = C.VALIDATE, caption = { "ilc.validate" }, tooltip = { "ilc.validate-tooltip" },
  })
  H.style_btn(validate, 90)

  local run = H.add(bottom, {
    type = "button", name = C.RUN, style = "confirm_button",
    caption = { "ilc.execute" }, tooltip = { "ilc.execute-tooltip" },
  })
  H.style_btn(run, 100)

  st.gui = {
    frame = frame,
    edit = edit,
    view = view,
    label = label,
    mode_btn = mode_btn,
    list = list,
    search = search,
    left = left,
    right = right,
    minmax = minmax,
    run = run,
  }

  M.apply_layout(player)
  script_list.rebuild(player)
  -- Existing code → preview; empty editor → edit.
  if type(st.raw) == "string" and not st.raw:match("^%s*$") then
    editor.show_preview(player)
  else
    editor.show_edit(player)
    if st.hotkey_execute then
      M.release_editor_focus(player)
    end
  end
  frame.bring_to_front()
end

function M.toggle_minmax(player)
  local g, st = state.gui(player)
  if not g then return end
  st.minimized = not st.minimized
  M.apply_layout(player)
  g.frame.auto_center = true
  if st.mode == "edit" then M.focus(player) end
end

function M.toggle(player)
  if player.gui.screen[C.MAIN] then
    M.close(player)
  else
    M.open(player)
  end
end

return M
