-- Per-player runtime state stored in `storage.ilc`.

local M = {}

function M.store()
  storage.ilc = storage.ilc or {}
  storage.ilc.players = storage.ilc.players or {}
  storage.ilc.library = storage.ilc.library or {}
  return storage.ilc
end

function M.player(index)
  local players = M.store().players
  local s = players[index]
  if not s then
    s = { raw = "", mode = "edit", minimized = false, hotkey_execute = true }
    players[index] = s
  end
  if s.mode == nil then s.mode = "edit" end
  if s.minimized == nil then s.minimized = false end
  -- Default ON so Ctrl+Enter works after a fresh join / old saves.
  if s.hotkey_execute == nil then s.hotkey_execute = true end
  return s
end

function M.gui(player)
  local st = M.player(player.index)
  local g = st.gui
  if g and g.frame and g.frame.valid then return g, st end
  st.gui = nil
  return nil, st
end

return M
