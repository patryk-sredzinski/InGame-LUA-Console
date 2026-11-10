-- Executes console code in a player-scoped environment (admin-only).

local C = require("src.constants")
local state = require("src.state")
local dialogs = require("src.dialogs")
local editor = require("src.editor")
local H = require("src.helpers")

local M = {}

local function fmt(v)
  if type(v) == "string" then return v end
  return serpent.line(v, { nocode = true, comment = false })
end

local function pack(...)
  return { n = select("#", ...), ... }
end

local function sync_raw(st)
  local g = st.gui
  if g and g.edit and g.edit.valid and g.edit.visible then
    st.raw = g.edit.text or st.raw
  end
end

-- Extract line number from Lua error messages like:
-- [string "=console"]:12: unexpected symbol near '...'
local function parse_error_line(msg)
  if type(msg) ~= "string" then return nil end
  local n = msg:match("%]:(%d+):")
  if not n then n = msg:match(":([0-9]+):") end
  return n and tonumber(n) or nil
end

local function report_error(player, err)
  local msg = tostring(err)
  editor.show_preview(player, parse_error_line(msg))
  dialogs.open_error(player, msg)
end

function M.run(player)
  local st = state.player(player.index)
  if not player.admin then
    dialogs.open_error(player, { "ilc.admin-only" })
    return
  end

  sync_raw(st)
  local code = st.raw or ""
  if code:match("^%s*$") then return end

  -- Vanilla /c sets game.player; this mod runs via load(), so mirror it
  -- with a thin proxy. Scripts can use `player` or `game.player`.
  local game_proxy = setmetatable({ player = player }, {
    __index = game,
    __newindex = function(_, k, v) game[k] = v end,
  })

  local env = setmetatable({
    player = player,
    surface = player.surface,
    force = player.force,
    game = game_proxy,
    print = function(...)
      local parts = {}
      for i = 1, select("#", ...) do parts[i] = fmt((select(i, ...))) end
      player.print(table.concat(parts, "  "))
    end,
  }, {
    __index = function(_, k)
      local ok, v = pcall(function() return _G[k] end)
      if ok then return v end
    end,
  })

  local fn = load("return " .. code, "=console", "t", env)
  local err
  if not fn then
    fn, err = load(code, "=console", "t", env)
  end
  if not fn then
    report_error(player, err)
    return
  end

  local res = pack(pcall(fn))
  if not res[1] then
    report_error(player, res[2])
    return
  end

  -- Print returned values like vanilla /c (skip the pcall success flag).
  for i = 2, res.n do
    player.print(fmt(res[i]), { sound = defines.print_sound.never })
  end

  H.play(player, "utility/console_player_resumed_game")
end

-- Dry-run: compile only, do not execute.
function M.validate(player)
  local st = state.player(player.index)
  sync_raw(st)

  local code = st.raw or ""
  if code:match("^%s*$") then
    dialogs.open_error(player, { "ilc.nothing-to-validate" })
    return
  end

  local fn, err = load("return " .. code, "=console", "t")
  if not fn then
    fn, err = load(code, "=console", "t")
  end
  if not fn then
    report_error(player, err)
    return
  end

  editor.show_preview(player)
  player.print({ "ilc.validate-ok" }, { color = C.COLOR_OK, sound = defines.print_sound.never })
  H.play(player, "utility/console_player_resumed_game")
end

return M
