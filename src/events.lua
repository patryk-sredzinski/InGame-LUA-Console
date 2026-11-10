-- Registers all script / GUI / command handlers.

local C = require("src.constants")
local state = require("src.state")
local editor = require("src.editor")
local dialogs = require("src.dialogs")
local scripts = require("src.scripts")
local runner = require("src.runner")
local console = require("src.console")
local buttons = require("src.buttons")
local script_list = require("src.script_list")
local library = require("src.library")

local M = {}

local function setup_player(player)
  if not player then return end
  -- Factorio persists screen GUI in the save; always start with console closed.
  console.close(player)
  buttons.remove(player)
  buttons.ensure(player)
  library.load(player)
end

function M.register()
  script.on_init(function()
    state.store()
    for _, player in pairs(game.players) do setup_player(player) end
  end)

  script.on_configuration_changed(function()
    state.store()
    library.migrate_all()
    for _, player in pairs(game.players) do setup_player(player) end
  end)

  script.on_event(defines.events.on_player_created, function(e)
    setup_player(game.get_player(e.player_index))
  end)

  script.on_event(defines.events.on_player_removed, function(e)
    library.remove(e.player_index)
  end)

  script.on_event(defines.events.on_gui_click, function(e)
    local el = e.element
    if not (el and el.valid) then return end
    local name = el.name
    if name:sub(1, 4) ~= "ilc_" then return end
    local player = game.get_player(e.player_index)
    if not player then return end
    local id = el.tags and el.tags.id

    if name == C.BTN_TOP then
      console.toggle(player)
      return
    end
    if name == C.EDIT or name == C.SEARCH or name == C.HOTKEY_EXECUTE then return end

    if name == C.CLOSE then
      console.close(player)
    elseif name == C.MINMAX then
      console.toggle_minmax(player)
    elseif name == C.MODE_BTN then
      editor.toggle_mode(player)
    elseif name == C.VALIDATE then
      runner.validate(player)
      console.focus(player)
    elseif name == C.RUN then
      runner.run(player)
      console.focus(player)
    elseif name == C.SAVE then
      dialogs.open_save(player)
    elseif name == C.NEW then
      scripts.new(player)
    elseif name == C.LOAD or name == C.LOAD_ICON then
      scripts.load(player, id)
    elseif name == C.DELETE then
      dialogs.open_confirm(player, id)
    elseif name == C.CONFIRM_YES then
      scripts.delete(player, id)
      console.focus(player)
    elseif name == C.CONFIRM_NO or name == C.SAVE_CANCEL then
      dialogs.close(player)
      console.focus(player)
    elseif name == C.SAVE_OK then
      scripts.save(player)
      console.focus(player)
    elseif name == C.IO_BTN then
      dialogs.open_io(player)
    elseif name == C.IO_IMPORT then
      dialogs.do_import(player)
      console.focus(player)
    elseif name == C.IO_CLOSE or name == C.ERR_CLOSE then
      dialogs.close(player)
      console.focus(player)
    elseif name == C.ERR_COPY then
      dialogs.copy_error(player)
    end
  end)

  script.on_event(defines.events.on_gui_text_changed, function(e)
    local el = e.element
    if not (el and el.valid) then return end
    if el.name == C.EDIT then
      state.player(e.player_index).raw = e.text
    elseif el.name == C.SEARCH then
      local player = game.get_player(e.player_index)
      if not player then return end
      state.player(e.player_index).search = e.text
      script_list.rebuild(player)
    end
  end)

  local function execute_from_hotkey(player)
    local st = state.player(player.index)
    if not st.hotkey_execute then return end
    local g = st.gui
    if g and g.edit and g.edit.valid then
      st.raw = g.edit.text or st.raw
    end
    if type(st.raw) ~= "string" or st.raw:match("^%s*$") then return end
    runner.run(player)
    -- Only needed while the console is open: keep focus off the text-box.
    if player.gui.screen[C.MAIN] then
      console.release_editor_focus(player)
    end
  end

  script.on_event(defines.events.on_gui_checked_state_changed, function(e)
    local el = e.element
    if not (el and el.valid and el.name == C.HOTKEY_EXECUTE) then return end
    local player = game.get_player(e.player_index)
    local st = state.player(e.player_index)
    st.hotkey_execute = el.state and true or false
    if not player then return end
    if st.hotkey_execute then
      console.release_editor_focus(player)
    else
      console.focus(player)
    end
  end)

  script.on_event(defines.events.on_gui_confirmed, function(e)
    local el = e.element
    if not (el and el.valid) then return end
    local player = game.get_player(e.player_index)
    if not player then return end
    if el.name == C.SAVE_TITLE then
      scripts.save(player)
      console.focus(player)
      return
    end
    -- Some Factorio builds may confirm a text-box with Ctrl+Enter.
    if el.name == C.EDIT and e.control then
      execute_from_hotkey(player)
    end
  end)

  script.on_event(defines.events.on_gui_closed, function(e)
    local el = e.element
    if not (el and el.valid) then return end
    local player = game.get_player(e.player_index)
    if not player then return end
    if el.name == C.MAIN then
      local st = state.player(player.index)
      -- Opening a modal also closes MAIN; keep the console in that case.
      if st.suppress_main_close then
        st.suppress_main_close = false
        return
      end
      local screen = player.gui.screen
      if screen[C.SAVE_DLG] or screen[C.CONFIRM_DLG] or screen[C.IO_DLG] or screen[C.ERR_DLG] then
        return
      end
      console.close(player)
    elseif el.name == C.ERR_DLG or el.name == C.SAVE_DLG or el.name == C.CONFIRM_DLG or el.name == C.IO_DLG then
      dialogs.close(player)
      console.focus(player)
    end
  end)

  script.on_event(defines.events.on_player_joined_game, function(e)
    setup_player(game.get_player(e.player_index))
  end)

  script.on_event("ilc-toggle", function(e)
    local player = game.get_player(e.player_index)
    if player then console.toggle(player) end
  end)

  script.on_event("ilc-execute", function(e)
    local player = game.get_player(e.player_index)
    if player then execute_from_hotkey(player) end
  end)

  commands.add_command("luaconsole", { "ilc.command-help" }, function(cmd)
    local player = cmd.player_index and game.get_player(cmd.player_index)
    if player then console.toggle(player) end
  end)
end

return M
