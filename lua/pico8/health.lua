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
