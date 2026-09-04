local config = require "pico8.config"
local util = require "pico8.util"

local M = {}

--- `:checkhealth pico8`
function M.check()
  local h = vim.health
  h.start "pico8.nvim"

  local opts = config.options

  if vim.fn.has "nvim-0.10" == 0 then
    h.error "nvim 0.10+ required"
  else
    h.ok("nvim " .. tostring(vim.version()))
  end

  if vim.fn.executable(opts.pico8_cmd) == 1 then
    h.ok("pico8 binary: " .. vim.fn.exepath(opts.pico8_cmd))
  else
    h.error(("%q not found on PATH"):format(opts.pico8_cmd), {
      "Install PICO-8 from https://www.lexaloffle.com/pico-8.php",
      "Or set pico8_cmd to its absolute path.",
    })
  end

  if vim.fn.executable "lua-language-server" == 1 then
    h.ok "lua-language-server found (completion and hover for the PICO-8 API)"
  else
    h.warn("lua-language-server not found", {
      "Without it you get no completion. Install it from your package manager.",
    })
  end

  if vim.fn.executable "pico8-ls" == 1 then
    h.ok "pico8-ls found (diagnostics inside .p8 carts)"
  else
    h.info("pico8-ls not found (optional)", {
      "It is not on npm; build it from https://github.com/japhib/pico8-ls",
      "See scripts/install-pico8-ls.sh in this plugin.",
    })
  end

  local types = util.types_dir()
  if vim.uv.fs_stat(types .. "/pico8.lua") then
    h.ok("API definitions: " .. types)
  else
    h.error("bundled definitions missing at " .. types)
  end

  if vim.uv.fs_stat(opts.carts_dir) then
    h.ok("carts dir: " .. opts.carts_dir)
  else
    h.info("carts dir does not exist yet: " .. opts.carts_dir .. " (created on first :Pico8New)")
  end

  M.check_luarc(h, types)
end

--- lua_ls prefers a `.luarc.json` at the workspace root over anything the
--- client sends, so one sitting above the current file replaces our settings
--- wholesale rather than adding to them. That is silent: the API just reads as
--- undefined globals. Check the ones that would actually win.
---@param h table vim.health
---@param types string
function M.check_luarc(h, types)
  local roots = {}
  for _, dir in ipairs { vim.fn.getcwd(), config.options.carts_dir } do
    dir = vim.fn.expand(dir)
    local found = vim.fs.find(".luarc.json", { path = dir, upward = true, type = "file" })[1]
    if found and not vim.tbl_contains(roots, found) then
      table.insert(roots, found)
    end
  end

  for _, file in ipairs(roots) do
    local ok, decoded = pcall(vim.json.decode, table.concat(vim.fn.readfile(file), "\n"))
    if not ok or type(decoded) ~= "table" then
      h.warn(".luarc.json is not valid JSON: " .. file, {
        "lua_ls ignores it and falls back to our settings, but fix or delete it.",
      })
    else
      local library = vim.tbl_get(decoded, "workspace", "library") or {}
      local covered = false
      for _, path in ipairs(library) do
        if vim.fn.expand(path) == types then
          covered = true
        end
      end

      if covered then
        h.ok(".luarc.json points at our definitions: " .. file)
      else
        h.warn(".luarc.json overrides our lua_ls settings: " .. file, {
          "It wins over anything this plugin sends, so the PICO-8 API will read",
          "as undefined globals. Add this to its workspace.library:",
          "  " .. types,
          "Or delete the file and let the plugin configure lua_ls.",
        })
      end
    end
  end
end

--- `:Pico8Info` -- a quick, non-health summary.
function M.info()
  local opts = config.options
  local lines = {
    "pico8.nvim",
    "  plugin root:  " .. util.plugin_root(),
    "  types dir:    " .. util.types_dir(),
    "  carts dir:    " .. opts.carts_dir,
    "  pico8 cmd:    "
      .. opts.pico8_cmd
      .. " ("
      .. (vim.fn.exepath(opts.pico8_cmd) ~= "" and "found" or "MISSING")
      .. ")",
    "  include file: " .. opts.include_file,
  }
  util.notify(table.concat(lines, "\n"))
end

return M
