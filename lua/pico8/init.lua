local config = require "pico8.config"

local M = {}

M.config = config

--- Lazily re-exported so `require("pico8")` stays cheap.
setmetatable(M, {
  __index = function(_, key)
    local modules = { run = "pico8.run", cart = "pico8.cart", lsp = "pico8.lsp", util = "pico8.util" }
    if modules[key] then
      return require(modules[key])
    end
  end,
})

---@param opts Pico8Config|nil
function M.setup(opts)
  config.setup(opts)

  require("pico8.ft").setup()
  require("pico8.lsp").setup()
  require("pico8.keymaps").setup()

  return M
end

return M
