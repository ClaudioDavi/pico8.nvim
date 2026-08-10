#!/usr/bin/env lua
--- Check types/pico8.lua against the PICO-8 manual.
---
--- Parses the API signatures out of pico-8_manual.txt and compares them to the
--- annotated stubs, reporting:
---
---   * functions in the manual with no stub          (missing coverage)
---   * stubs with no manual entry                    (typo or invention)
---   * arity or optionality mismatches               (wrong signature)
---
--- Usage:
---   lua scripts/check-api.lua [path/to/pico-8_manual.txt]
---   lua scripts/check-api.lua --list        # print the parsed manual API
---   lua scripts/check-api.lua --quiet       # exit status only
---
--- Exits 0 if everything matches, 1 otherwise, 2 if the manual can't be read.

local MANUAL_CANDIDATES = {
  "/opt/pico-8/pico-8_manual.txt",
  "/usr/share/pico-8/pico-8_manual.txt",
  os.getenv "HOME" .. "/pico-8/pico-8_manual.txt",
  "/Applications/PICO-8.app/Contents/Resources/pico-8_manual.txt",
}

--- Entries that appear in the manual's API sections but are not functions we
--- want stubs for, or are documented under a different name.
local IGNORE = {
  -- Lua keywords and prose that share the shape of a signature line.
  FUNCTION_NAME = true,
  WHILE = true,
  FUNCTION = true,
}

--- Functions PICO-8 provides that the manual only mentions in prose, never as
--- an indented signature line. Treated as documented so they are not reported
--- as inventions -- each was verified callable with `pico8 -x`.
local PROSE_ONLY = {
  yield = "()",
}

--- Manual signatures the stubs deliberately spell differently, with a reason.
--- Keep this small: each entry is a place the check is weakened.
local KNOWN_DIFFS = {
  -- The manual writes `PAL(C0, C1, [P])` and `PAL(TBL, [P])` as two entries.
  -- One stub covers both via a union type on the first parameter.
  pal = "two documented forms merged into one stub",
  -- Manual: `CAMERA([X, Y])` -- a single optional pair. The stub takes two
  -- independently optional numbers, which is how it is actually called.
  camera = "bracketed pair documented as one optional group",
  -- Manual: `LINE(X0, Y0, [X1, Y1, [COL]])` -- nested optional groups.
  line = "nested optional groups flattened",
  -- Manual typo: `SSPR(... [FLIP_X], [FLIP_Y]]` -- unbalanced bracket.
  sspr = "manual has an unbalanced bracket in this signature",
  -- Manual typo: `RAWEQUAL(TBL1,TBL2` -- unclosed paren.
  rawequal = "manual signature is missing its closing paren",
  -- Variadic in the manual's prose, written as `...` in the stub.
  poke = "variadic",
  chr = "variadic",
  coresume = "variadic",
  yield = "variadic",
  peek = "returns n values",
  ord = "returns num_results values",

  -- Manual typo: `RELOAD(DEST_ADDR, SOURCE_ADDR LEN, [FILENAME])` is missing a
  -- comma, so it parses as three parameters instead of four.
  reload = "manual signature is missing a comma between source_addr and len",

  -- The stubs below mark the first parameter optional where the manual's
  -- signature line shows it as required. Verified against PICO-8 v0.2.7 with
  -- `pico8 -x`: each of these is callable with no arguments.
  clip = "verified: clip() with no arguments resets the clip region",
  palt = "verified: palt() with no arguments resets transparency",
  fillp = "verified: fillp() with no arguments is legal",
  cursor = "verified: cursor() with no arguments is legal",
  rnd = "verified: rnd() with no arguments returns 0..1",
  --   PRINT is documented twice: PRINT(STR, X, Y, [COL]) and PRINT(STR, [COL]).
  print = "two documented forms merged; x and y optional in the second",

  -- `t` is documented as prose alongside TIME() rather than as its own entry.
  t = "documented as an alias of time() in prose",
}

local function read_lines(path)
  local fh = io.open(path, "r")
  if not fh then
    return nil
  end
  local lines = {}
  for line in fh:lines() do
    lines[#lines + 1] = line
  end
  fh:close()
  return lines
end

local function find_manual(explicit)
  if explicit then
    return explicit, read_lines(explicit)
  end
  for _, path in ipairs(MANUAL_CANDIDATES) do
    local lines = read_lines(path)
    if lines then
      return path, lines
    end
  end
  return nil, nil
end

--- Split a manual parameter list into names, tracking optionality.
---
--- The manual marks optional parameters with square brackets, sometimes
--- grouping several: `LINE(X0, Y0, [X1, Y1, [COL]])`. Bracket depth greater
--- than zero means optional.
---@param argstr string
---@return {name: string, optional: boolean}[]
local function parse_args(argstr)
  local args, buf, depth = {}, "", 0

  local function flush()
    local name = buf:gsub("^%s+", ""):gsub("%s+$", "")
    if name ~= "" then
      args[#args + 1] = { name = name:lower(), optional = depth > 0 }
    end
    buf = ""
  end

  for i = 1, #argstr do
    local c = argstr:sub(i, i)
    if c == "[" then
      flush()
      depth = depth + 1
    elseif c == "]" then
      flush()
      depth = math.max(0, depth - 1)
    elseif c == "," then
      flush()
    else
      buf = buf .. c
    end
  end
  flush()

  return args
end

--- Extract API declarations from the manual.
---
--- Declarations sit at exactly four spaces of indentation with an all-caps
--- name. Lines containing a comment, a string literal, a hex constant or an
--- operator are usage examples rather than declarations.
---@param lines string[]
---@return table<string, {args: table, line: integer, raw: string}>
local function parse_manual(lines)
  local api = {}

  for n, line in ipairs(lines) do
    local name, rest = line:match "^    ([A-Z_][A-Z0-9_]*)%((.*)$"
    if name then
      local is_example = line:find "%-%-" -- inline comment
        or line:find '"' -- string literal
        or line:find "0[xX]%x" -- hex constant
        or line:find "%s[=!<>]=%s" -- comparison
        -- Concatenation, but not the `...` of a variadic signature nor the
        -- `[P0, P1 ..]` shorthand the manual uses for "and so on".
        or (line:gsub("%.%.%.", ""):gsub("%s%.%.%]", "]")):find "%.%."
        or rest:match "^%)%w" -- POKE()ed
        -- Prose that opens with a call, e.g. "_DRAW() is normally called at
        -- 30fps, but ...", or "YIELD() any number of times". A declaration has
        -- nothing after its closing paren.
        or rest:match "^%)%s+%S"
        -- A declaration's parameters are upper-case identifiers, `...` or
        -- bracketed groups; three consecutive lower-case letters means prose.
        -- Checked on the parameters only, so `POKE(ADDR, VAL1, ...)` survives.
        or (rest:match "^(.-)%)" or rest):match "%l%l%l"
      if not is_example and not IGNORE[name] then
        -- Trim at the closing paren when there is one; the manual has two
        -- signatures with unbalanced brackets, so fall back to end-of-line.
        local argstr = rest:match "^(.-)%)%s*$" or rest:gsub("[%]%)]+%s*$", "")
        local key = name:lower()
        -- Keep the first occurrence: later ones are alternate forms.
        if not api[key] then
          api[key] = { args = parse_args(argstr), line = n, raw = line:gsub("^%s+", "") }
        end
      end
    end
  end

  return api
end

--- Extract function stubs and their @param annotations from the types file.
---@param lines string[]
---@return table<string, {args: table, line: integer}>
local function parse_stubs(lines)
  local stubs = {}
  local pending = {}

  for n, line in ipairs(lines) do
    local param, opt = line:match "^%-%-%-@param%s+([%w_]+)(%??)"
    if param then
      pending[#pending + 1] = { name = param:lower(), optional = opt == "?" }
    end

    local name, argstr = line:match "^function%s+([%w_]+)%s*%((.-)%)"
    if name then
      -- Prefer the annotations; fall back to the literal parameter list.
      local args = pending
      if #args == 0 then
        args = {}
        for a in argstr:gmatch "[^,%s]+" do
          args[#args + 1] = { name = a:lower(), optional = false }
        end
      end
      stubs[name:lower()] = { args = args, line = n }
      pending = {}
    elseif line:match "^%s*$" then
      -- A blank line ends an annotation block.
      pending = {}
    end
  end

  return stubs
end

local function summarise(args)
  local parts = {}
  for _, a in ipairs(args) do
    parts[#parts + 1] = a.optional and (a.name .. "?") or a.name
  end
  return "(" .. table.concat(parts, ", ") .. ")"
end

-- ---------------------------------------------------------------------------

local args = { ... }
local opts = { quiet = false, list = false, manual = nil }
for _, a in ipairs(args) do
  if a == "--quiet" or a == "-q" then
    opts.quiet = true
  elseif a == "--list" then
    opts.list = true
  elseif a == "--help" or a == "-h" then
    print "usage: check-api.lua [--list] [--quiet] [path/to/pico-8_manual.txt]"
    os.exit(0)
  else
    opts.manual = a
  end
end

local script_dir = (debug.getinfo(1, "S").source:sub(2):match "(.*)/" or ".")
local types_path = script_dir .. "/../types/pico8.lua"

local manual_path, manual_lines = find_manual(opts.manual)
if not manual_lines then
  io.stderr:write "error: could not find pico-8_manual.txt\n"
  io.stderr:write "  pass its path as an argument, or install PICO-8\n"
  os.exit(2)
end

local types_lines = read_lines(types_path)
if not types_lines then
  io.stderr:write("error: could not read " .. types_path .. "\n")
  os.exit(2)
end

local manual = parse_manual(manual_lines)
local stubs = parse_stubs(types_lines)

if opts.list then
  local names = {}
  for name in pairs(manual) do
    names[#names + 1] = name
  end
  table.sort(names)
  for _, name in ipairs(names) do
    print(("%-12s %s"):format(name, summarise(manual[name].args)))
  end
  os.exit(0)
end

local missing, extra, mismatched = {}, {}, {}

for name, entry in pairs(manual) do
  local stub = stubs[name]
  if not stub then
    missing[#missing + 1] = { name = name, entry = entry }
  elseif not KNOWN_DIFFS[name] then
    local m, s = entry.args, stub.args
    local problem = nil
    if #m ~= #s then
      problem = ("arity: manual %d, stub %d"):format(#m, #s)
    else
      for i = 1, #m do
        if m[i].optional ~= s[i].optional then
          problem = ("parameter %d (%s): manual says %s, stub says %s"):format(
            i,
            m[i].name,
            m[i].optional and "optional" or "required",
            s[i].optional and "optional" or "required"
          )
          break
        end
      end
    end
    if problem then
      mismatched[#mismatched + 1] = { name = name, problem = problem, manual = m, stub = s, entry = entry }
    end
  end
end

-- Callbacks are declared by the user, not documented as API calls.
local CALLBACKS = { _init = true, _update = true, _update60 = true, _draw = true }
for name, stub in pairs(stubs) do
  if not manual[name] and not CALLBACKS[name] and not PROSE_ONLY[name] then
    extra[#extra + 1] = { name = name, line = stub.line }
  end
end

local function by_name(a, b)
  return a.name < b.name
end
table.sort(missing, by_name)
table.sort(extra, by_name)
table.sort(mismatched, by_name)

local manual_count = 0
for _ in pairs(manual) do
  manual_count = manual_count + 1
end

if not opts.quiet then
  print(("manual: %s"):format(manual_path))
  print(("types:  %s"):format(types_path))
  print(("parsed %d documented functions, %d stubs"):format(
    manual_count,
    (function()
      local n = 0
      for _ in pairs(stubs) do
        n = n + 1
      end
      return n
    end)()
  ))
  print()

  if #missing > 0 then
    print(("MISSING (%d) -- documented but not in types/pico8.lua:"):format(#missing))
    for _, m in ipairs(missing) do
      print(("  %-12s manual:%d  %s"):format(m.name, m.entry.line, m.entry.raw))
    end
    print()
  end

  if #extra > 0 then
    print(("UNKNOWN (%d) -- in types/pico8.lua but not documented:"):format(#extra))
    for _, e in ipairs(extra) do
      print(("  %-12s types:%d"):format(e.name, e.line))
    end
    print()
  end

  if #mismatched > 0 then
    print(("MISMATCHED (%d) -- signature differs:"):format(#mismatched))
    for _, d in ipairs(mismatched) do
      print(("  %s  %s"):format(d.name, d.problem))
      print(("    manual:%d %s"):format(d.entry.line, summarise(d.manual)))
      print(("    stub          %s"):format(summarise(d.stub)))
    end
    print()
  end

  local skipped = 0
  for _ in pairs(KNOWN_DIFFS) do
    skipped = skipped + 1
  end
  if skipped > 0 then
    print(("note: %d signatures exempt from arity checks (see KNOWN_DIFFS)"):format(skipped))
  end

  if #missing == 0 and #extra == 0 and #mismatched == 0 then
    print "OK: every documented function has a matching stub"
  end
end

os.exit((#missing == 0 and #extra == 0 and #mismatched == 0) and 0 or 1)
