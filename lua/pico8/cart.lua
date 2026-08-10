local config = require "pico8.config"
local util = require "pico8.util"

local M = {}

--- Minimal cart shell. Code lives in the #include so it can be edited as
--- plain Lua; the single blank sprite row keeps PICO-8's sprite editor happy.
---@param name string
---@return string[]
local function cart_lines(name)
  local opts = config.options
  return {
    "pico-8 cartridge // http://www.pico-8.com",
    "version " .. opts.cart_version,
    "__lua__",
    "#include " .. opts.include_file,
    "__gfx__",
    ("0"):rep(32),
  }
end

---@param name string
---@return string[]
local function stub_lines(name)
  return {
    "-- " .. name,
    "",
    "function _init()",
    "end",
    "",
    "function _update()",
    "end",
    "",
    "function _draw()",
    "  cls(1)",
    ('  print("%s", 4, 4, 7)'):format(name),
    "end",
  }
end

--- Scaffold a new cart project: <carts_dir>/<name>/{<name>.p8, main.lua}
---
--- Never overwrites: an existing cart aborts, an existing include file is left
--- alone so re-running cannot destroy code.
---@param name string
---@param dir string|nil Override the parent directory.
---@return string|nil cart Path to the cart, or nil on failure.
function M.new(name, dir)
  local opts = config.options

  if not name or name == "" then
    util.notify("cart name required", vim.log.levels.ERROR)
    return nil
  end
  if name:match "[/\\]" then
    util.notify("cart name must not contain a path separator", vim.log.levels.ERROR)
    return nil
  end

  local parent = vim.fn.expand(dir or opts.carts_dir)
  local proj = parent .. "/" .. name
  local cart = proj .. "/" .. name .. ".p8"
  local include = proj .. "/" .. opts.include_file

  if vim.uv.fs_stat(cart) then
    util.notify(cart .. " already exists", vim.log.levels.ERROR)
    return nil
  end

  vim.fn.mkdir(proj, "p")
  vim.fn.writefile(cart_lines(name), cart)

  if not vim.uv.fs_stat(include) then
    vim.fn.writefile(stub_lines(name), include)
  end

  return cart
end

return M
