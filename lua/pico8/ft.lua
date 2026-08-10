local config = require "pico8.config"

local M = {}

--- Markers that begin each section of a .p8 cart.
M.section_markers = { "__lua__", "__gfx__", "__gff__", "__label__", "__map__", "__sfx__", "__music__" }

--- Fold expression: each `__section__` marker starts a fold.
---
--- Global because 'foldexpr' is evaluated as a vim expression, which cannot
--- see Lua locals.
---@return string
function _G.Pico8FoldExpr()
  local line = vim.fn.getline(vim.v.lnum)
  return line:match "^__%w+__$" and ">1" or "="
end

function M.setup()
  local opts = config.options

  vim.filetype.add {
    extension = {
      p8 = "p8",
    },
    pattern = {
      -- .p8.lua files are pure Lua includes, not carts.
      [".*%.p8%.lua"] = "lua",
    },
  }

  -- No treesitter grammar exists for the .p8 container, so reuse Lua's. The
  -- __gfx__/__map__ blocks at the end will highlight oddly; they are hex data.
  if vim.treesitter and vim.treesitter.language and vim.treesitter.language.register then
    pcall(vim.treesitter.language.register, "lua", "p8")
  end

  local group = vim.api.nvim_create_augroup("pico8_ft", { clear = true })

  vim.api.nvim_create_autocmd("FileType", {
    group = group,
    pattern = "p8",
    callback = function(args)
      -- PICO-8 writes carts with one-space indentation and counts a tab as a
      -- single token, so match its conventions.
      vim.bo[args.buf].expandtab = true
      vim.bo[args.buf].shiftwidth = 1
      vim.bo[args.buf].tabstop = 1
      vim.bo[args.buf].commentstring = "-- %s"

      if opts.folding.enable then
        vim.wo.foldmethod = "expr"
        vim.wo.foldexpr = "v:lua.Pico8FoldExpr()"
        vim.wo.foldlevel = opts.folding.start_closed and 0 or 99
      end
    end,
  })
end

return M
