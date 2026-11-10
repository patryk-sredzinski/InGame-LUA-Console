-- Modal dialogs: error, confirm-delete, save, import/export.

local C = require("src.constants")
local H = require("src.helpers")
local state = require("src.state")
local library = require("src.library")
local script_list = require("src.script_list")

local M = {}

-- Open a modal without letting on_gui_closed(MAIN) destroy the console.
local function set_opened(player, dlg)
  state.player(player.index).suppress_main_close = true
  player.opened = dlg
end

local function restore_console_opened(player)
  local g = state.gui(player)
  if g and g.frame and g.frame.valid then
    player.opened = g.frame
  elseif player.opened then
    player.opened = nil
  end
end

function M.close(player)
  local had_opened_dialog = false
  for _, name in ipairs({ C.SAVE_DLG, C.CONFIRM_DLG, C.IO_DLG, C.ERR_DLG }) do
    local el = player.gui.screen[name]
    if el then
      if player.opened == el then had_opened_dialog = true end
      el.destroy()
    end
  end
  local st = state.player(player.index)
  st.dialog = nil
  -- Always clear so a missed on_gui_closed(MAIN) cannot swallow Escape later.
  st.suppress_main_close = false
  if had_opened_dialog then
    restore_console_opened(player)
  end
end

function M.open_error(player, message)
  M.close(player)

  local dlg = H.add(player.gui.screen, {
    type = "frame", name = C.ERR_DLG, caption = { "ilc.error-title" }, direction = "vertical",
  })
  dlg.auto_center = true
  dlg.style.padding = C.PAD

  -- Plain strings (runtime Lua errors) go in a selectable text-box for Copy.
  -- LocalisedString messages are shown as a label.
  local box
  if type(message) == "string" then
    box = dlg.add { type = "text-box", name = C.ERR_TEXT, text = message }
    box.word_wrap = true
    box.read_only = true
    box.style.width = 480
    box.style.height = 160
    H.set_mono(box)
    pcall(function() box.rich_text_setting = defines.rich_text_setting.disabled end)
  else
    local msg = dlg.add { type = "label", caption = message }
    msg.style.single_line = false
    msg.style.maximal_width = 480
  end

  local row = dlg.add { type = "flow", direction = "horizontal" }
  row.style.top_margin = C.PAD
  row.style.horizontal_spacing = C.PAD
  row.style.vertical_align = "center"

  local close = H.add(row, {
    type = "button", name = C.ERR_CLOSE, style = "back_button", caption = { "ilc.close" },
  })
  H.style_btn(close, 100)

  local fill = row.add { type = "empty-widget" }
  fill.style.horizontally_stretchable = true

  if box then
    local copy = H.add(row, {
      type = "button", name = C.ERR_COPY, style = "confirm_button",
      caption = { "ilc.copy" }, tooltip = { "ilc.copy-tooltip" },
    })
    H.style_btn(copy, 100)
  end

  state.player(player.index).err_box = box
  if box then
    box.focus()
    box.select_all()
  end
  set_opened(player, dlg)
  H.play(player, "utility/scenario_message")
end

function M.copy_error(player)
  local st = state.player(player.index)
  local box = st.err_box
  if not (box and box.valid) then return end
  box.focus()
  box.select_all()
  H.play(player, "utility/confirm")
end

function M.open_confirm(player, id)
  local entry = id and library.find(library.load(player), id)
  if not entry then return end
  M.close(player)

  local dlg = H.add(player.gui.screen, {
    type = "frame", name = C.CONFIRM_DLG, caption = { "ilc.confirm-title" }, direction = "vertical",
  })
  dlg.auto_center = true
  dlg.style.padding = C.PAD

  local msg = dlg.add { type = "label", caption = { "ilc.confirm-delete", entry.title } }
  msg.style.single_line = false
  msg.style.maximal_width = 320

  local row = dlg.add { type = "flow", direction = "horizontal" }
  row.style.top_margin = C.PAD
  row.style.horizontal_spacing = C.PAD
  local no = H.add(row, { type = "button", name = C.CONFIRM_NO, style = "back_button", caption = { "ilc.cancel" } })
  H.style_btn(no)
  local fill = row.add { type = "empty-widget" }
  fill.style.horizontally_stretchable = true
  local yes = H.add(row, {
    type = "button", name = C.CONFIRM_YES, style = "red_confirm_button",
    caption = { "ilc.delete" }, tags = { id = id },
  })
  H.style_btn(yes)
  set_opened(player, dlg)
end

function M.open_save(player)
  local g, st = state.gui(player)
  if not g then return end
  if g.edit and g.edit.valid and g.edit.visible then
    st.raw = g.edit.text or st.raw
  end
  if type(st.raw) ~= "string" or st.raw:match("^%s*$") then
    M.open_error(player, { "ilc.nothing-to-save" })
    return
  end
  M.close(player)

  local current = st.current_id and library.find(library.load(player), st.current_id) or nil

  local dlg = H.add(player.gui.screen, {
    type = "frame", name = C.SAVE_DLG, caption = { "ilc.save-title" }, direction = "vertical",
  })
  dlg.auto_center = true
  dlg.style.padding = C.PAD

  local grid = dlg.add { type = "table", column_count = 2 }
  grid.style.horizontal_spacing = C.PAD
  grid.style.vertical_spacing = C.PAD

  grid.add { type = "label", caption = { "ilc.title-label" } }
  local title = grid.add { type = "textfield", name = C.SAVE_TITLE, text = current and current.title or "" }
  title.style.width = 280
  title.style.height = C.BTN_H

  grid.add { type = "label", caption = { "ilc.icon-label" } }
  local icon = grid.add { type = "choose-elem-button", name = C.SAVE_ICON, elem_type = "signal" }
  if current and current.icon then
    pcall(function() icon.elem_value = current.icon end)
  end

  local row = dlg.add { type = "flow", direction = "horizontal" }
  row.style.top_margin = C.PAD
  row.style.horizontal_spacing = C.PAD
  local cancel = H.add(row, { type = "button", name = C.SAVE_CANCEL, style = "back_button", caption = { "ilc.cancel" } })
  H.style_btn(cancel)
  local fill = row.add { type = "empty-widget" }
  fill.style.horizontally_stretchable = true
  local ok = H.add(row, { type = "button", name = C.SAVE_OK, style = "confirm_button", caption = { "ilc.save" } })
  H.style_btn(ok)

  st.dialog = { title = title, icon = icon }
  set_opened(player, dlg)
  if title.valid then
    title.focus()
    title.select_all()
  end
end

function M.open_io(player)
  local g, st = state.gui(player)
  if not g then return end
  M.close(player)

  local dlg = H.add(player.gui.screen, {
    type = "frame", name = C.IO_DLG, caption = { "ilc.io-title" }, direction = "vertical",
  })
  dlg.auto_center = true
  dlg.style.padding = C.PAD

  local help = dlg.add { type = "label", caption = { "ilc.io-help" } }
  help.style.single_line = false
  help.style.maximal_width = 520

  local box = dlg.add { type = "text-box", name = C.IO_TEXT, text = helpers.table_to_json(library.load(player)) }
  box.word_wrap = true
  box.style.width = 520
  box.style.height = 220
  H.set_mono(box)
  pcall(function() box.rich_text_setting = defines.rich_text_setting.disabled end)

  local row = dlg.add { type = "flow", direction = "horizontal" }
  row.style.top_margin = C.PAD
  row.style.horizontal_spacing = C.PAD
  local close = H.add(row, { type = "button", name = C.IO_CLOSE, style = "back_button", caption = { "ilc.close" } })
  H.style_btn(close)
  local fill = row.add { type = "empty-widget" }
  fill.style.horizontally_stretchable = true
  local imp = H.add(row, { type = "button", name = C.IO_IMPORT, style = "confirm_button", caption = { "ilc.import" } })
  H.style_btn(imp)

  st.io_box = box
  set_opened(player, dlg)
  if box.valid then
    box.focus()
    box.select_all()
  end
end

function M.do_import(player)
  local st = state.player(player.index)
  local box = st.io_box
  if not (box and box.valid) then return end

  local incoming = library.parse(box.text)
  if not incoming then
    M.open_error(player, { "ilc.import-invalid" })
    return
  end

  local data = library.load(player)
  local added = 0
  local skipped = 0
  for _, s in ipairs(incoming.scripts) do
    if added >= C.IMPORT_MAX_SCRIPTS then
      skipped = skipped + 1
    elseif type(s) == "table" and type(s.code) == "string" then
      if #s.code > C.IMPORT_MAX_CODE_LEN then
        skipped = skipped + 1
      else
        local title = tostring(s.title or "Untitled")
        local duplicate = false
        for _, existing in ipairs(data.scripts) do
          if existing.title == title and existing.code == s.code then
            duplicate = true
            break
          end
        end
        if not duplicate then
          data.scripts[#data.scripts + 1] = {
            id = data.next_id,
            title = title,
            icon = library.sanitize_icon(s.icon),
            code = s.code,
          }
          data.next_id = data.next_id + 1
          added = added + 1
        end
      end
    end
  end

  library.persist(player, data)
  M.close(player)
  script_list.rebuild(player)
  H.play(player, "utility/confirm")
  player.print({ "ilc.imported", added }, { color = C.COLOR_OK })
  if skipped > 0 then
    player.print({ "ilc.import-skipped", skipped }, { color = C.COLOR_ERR })
  end
end

return M
