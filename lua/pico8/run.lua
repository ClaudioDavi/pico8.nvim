local config = require "pico8.config"
local util = require "pico8.util"

local M = {}

--- Handle of the PICO-8 process we started, if any.
---@type vim.SystemObj|nil
local proc = nil

--- Launch PICO-8 on a cart.
---
--- Detached, so nvim never blocks and PICO-8 outlives the editor.
---@param cart string|nil Cart path; defaults to the current buffer's cart.
function M.run(cart)
  local opts = config.options

  if vim.fn.executable(opts.pico8_cmd) == 0 then
    util.notify(("%q not found on PATH"):format(opts.pico8_cmd), vim.log.levels.ERROR)
    return
  end

  if not cart then
    local carts = util.find_carts(0)
    if #carts == 0 then
      util.notify("no .p8 cart found for this buffer", vim.log.levels.WARN)
      return
    elseif #carts > 1 then
      vim.ui.select(carts, { prompt = "Which cart?" }, function(choice)
        if choice then
          M.run(choice)
        end
      end)
      return
    end
    cart = carts[1]
  end

  -- Save first: PICO-8 reads from disk, and an #include is only resolved on
  -- load, so unsaved changes to main.lua would silently not appear.
  if vim.bo.modified and vim.bo.buftype == "" then
    vim.cmd "write"
  end

  local cmd = { opts.pico8_cmd }
  vim.list_extend(cmd, opts.run_args)
  table.insert(cmd, cart)

  proc = vim.system(cmd, { detach = true }, function(res)
    if res.code ~= 0 and res.code ~= 143 then
      vim.schedule(function()
        local err = (res.stderr or ""):gsub("%s+$", "")
        util.notify(("PICO-8 exited with %d%s"):format(res.code, err ~= "" and ": " .. err or ""), vim.log.levels.WARN)
      end)
    end
  end)

  util.notify("running " .. vim.fn.fnamemodify(cart, ":t"))
end

--- Terminate the PICO-8 process we launched.
function M.stop()
  if not proc then
    util.notify("no PICO-8 process started from nvim", vim.log.levels.WARN)
    return
  end
  proc:kill "sigterm"
  proc = nil
  util.notify "stopped PICO-8"
end

return M
