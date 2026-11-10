-- Turns Lua source into Factorio rich text ([color=#rrggbb]...[/color]).
local M = {}

local COLORS = {
  plain = "#d4d4d4",
  keyword = "#c586c0",
  literal = "#569cd6",
  string = "#ce9178",
  number = "#b5cea8",
  comment = "#6a9955",
  builtin = "#4ec9b0",
  func = "#dcdcaa",
  error = "#ff6b6b",
}

local function set(list)
  local t = {}
  for _, v in ipairs(list) do t[v] = true end
  return t
end

local KEYWORDS = set {
  "and", "break", "do", "else", "elseif", "end", "for", "function", "goto", "if",
  "in", "local", "not", "or", "repeat", "return", "then", "until", "while",
}
local LITERALS = set { "true", "false", "nil" }
local BUILTINS = set {
  "game", "script", "defines", "storage", "helpers", "rendering", "prototypes",
  "settings", "remote", "commands", "rcon", "serpent", "log", "localised_print",
  "table_size", "player", "surface", "force", "print", "require", "_G", "_ENV",
  "string", "table", "math", "pairs", "ipairs", "next", "type", "tostring",
  "tonumber", "select", "pcall", "xpcall", "error", "assert", "setmetatable",
  "getmetatable", "rawget", "rawset", "rawequal", "rawlen", "load",
}

-- Factorio rich-text literals for [ and ] so source code cannot form real tags.
local function escape_rich(text)
  return (text
    :gsub("%[", "\0LB\0")
    :gsub("%]", "[right-square-bracket]")
    :gsub("\0LB\0", "[left-square-bracket]"))
end

local function span(color, text)
  if text == "" then return "" end
  return "[color=" .. color .. "]" .. escape_rich(text) .. "[/color]"
end

local function utf8_len(s)
  local n = 0
  for _ in s:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
    n = n + 1
  end
  return n
end

-- Highlight a full chunk, preserving lexer state across newlines.
-- Returns an array of rich-text strings, one per source line.
function M.render_lines(code)
  code = (code or ""):gsub("\r", ""):gsub("\t", "    ")

  local line_parts = { {} }
  local plain = {}

  local function current_parts()
    return line_parts[#line_parts]
  end

  local function push_span(color, text)
    if text == "" then return end
    local i, n = 1, #text
    while i <= n do
      local nl = text:find("\n", i, true)
      local piece = text:sub(i, nl and (nl - 1) or n)
      if piece ~= "" then
        local parts = current_parts()
        parts[#parts + 1] = span(color, piece)
      end
      if not nl then break end
      line_parts[#line_parts + 1] = {}
      i = nl + 1
    end
  end

  local function flush()
    if #plain > 0 then
      push_span(COLORS.plain, table.concat(plain))
      plain = {}
    end
  end

  local function emit(color, text)
    flush()
    push_span(color, text)
  end

  local i, n = 1, #code
  while i <= n do
    local c = code:sub(i, i)

    if code:sub(i, i + 1) == "--" then
      local eq = code:match("^%-%-%[(=*)%[", i)
      local e
      if eq then
        local _, close_end = code:find("]" .. eq .. "]", i + 4 + #eq, true)
        e = close_end or n
      else
        e = (code:find("\n", i, true) or (n + 1)) - 1
      end
      emit(COLORS.comment, code:sub(i, e))
      i = e + 1

    elseif c == '"' or c == "'" then
      local j = i + 1
      while j <= n do
        local d = code:sub(j, j)
        if d == "\\" then
          j = j + 2
        elseif d == c then
          break
        elseif d == "\n" then
          j = j - 1
          break
        else
          j = j + 1
        end
      end
      local e = math.min(j, n)
      emit(COLORS.string, code:sub(i, e))
      i = e + 1

    elseif c == "[" and code:find("^%[=*%[", i) then
      local eq = code:match("^%[(=*)%[", i)
      local _, close_end = code:find("]" .. eq .. "]", i + 2 + #eq, true)
      local e = close_end or n
      emit(COLORS.string, code:sub(i, e))
      i = e + 1

    elseif c:find("%d") or (c == "." and code:find("^%.%d", i)) then
      local s, e = code:find("^0[xX]%x+", i)
      if not s then s, e = code:find("^%d+%.?%d*[eE][%+%-]?%d+", i) end
      if not s then s, e = code:find("^%d*%.?%d+", i) end
      if s then
        emit(COLORS.number, code:sub(s, e))
        i = e + 1
      else
        plain[#plain + 1] = c
        i = i + 1
      end

    elseif c:find("[%a_]") then
      local s, e = code:find("^[%w_]+", i)
      local word = code:sub(s, e)
      local before = code:sub(math.max(i - 1, 1), i - 1)
      local before2 = code:sub(math.max(i - 2, 1), i - 1)
      local is_field = i > 1 and (before == "." or before == ":") and before2 ~= ".."
      local is_call = code:find("^%s*%(", e + 1) ~= nil
      local color
      if is_field then
        if is_call then color = COLORS.func end
      elseif KEYWORDS[word] then
        color = COLORS.keyword
      elseif LITERALS[word] then
        color = COLORS.literal
      elseif BUILTINS[word] then
        color = COLORS.builtin
      elseif is_call then
        color = COLORS.func
      end
      if color then
        emit(color, word)
      else
        plain[#plain + 1] = word
      end
      i = e + 1

    elseif c == "\n" then
      flush()
      line_parts[#line_parts + 1] = {}
      i = i + 1

    else
      plain[#plain + 1] = c
      i = i + 1
    end
  end

  flush()

  local out = {}
  for _, parts in ipairs(line_parts) do
    out[#out + 1] = table.concat(parts)
  end
  if #out == 0 then out[1] = "" end
  return out
end

function M.render(code)
  return table.concat(M.render_lines(code), "\n")
end

function M.render_error_line(line)
  line = (line or ""):gsub("\t", "    ")
  local body = line == "" and " " or line
  local n = math.max(utf8_len(body), 1)
  return "[color=" .. COLORS.error .. "]▶ [/color][font=default-bold]"
    .. span(COLORS.error, body)
    .. "[/font]\n[color=" .. COLORS.error .. "]  " .. string.rep("▔", n) .. "[/color]"
end

return M
