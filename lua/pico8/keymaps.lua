local config = require "pico8.config"

local M = {}

function M.setup()
  local maps = config.options.keymaps

  local function set(lhs, rhs, desc)
    if lhs then -- false or nil disables the mapping
      vim.keymap.set("n", lhs, rhs, { desc = desc, silent = true })
    end
  end

  set(maps.run, function()
    require("pico8.run").run()
  end, "pico8: run cart")

  set(maps.stop, function()
    require("pico8.run").stop()
  end, "pico8: stop cart")

  set(maps.new, function()
    vim.cmd "Pico8New"
  end, "pico8: new cart")

  set(maps.toggle_folds, function()
    -- zR/zM equivalent, scoped to the data sections.
    vim.wo.foldlevel = vim.wo.foldlevel == 0 and 99 or 0
  end, "pico8: toggle data-section folds")
end

return M
