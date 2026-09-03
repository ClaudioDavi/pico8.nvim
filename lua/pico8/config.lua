local M = {}

---@class Pico8Config
---@field pico8_cmd string Path to the PICO-8 binary.
---@field run_args string[] Extra arguments passed before the cart path.
---@field carts_dir string Where `:Pico8New` scaffolds projects.
---@field include_file string Name of the Lua file the cart `#include`s.
---@field terminal table Where `:Pico8Run` sends PICO-8's output.
---@field lsp table LSP integration options.
---@field folding table Folding of the cart's binary data sections.
---@field keymaps table<string, string|false> Keymaps, or false to disable one.
---@field cart_version integer `version` header written into new carts.
local defaults = {
  pico8_cmd = "pico8",
  run_args = { "-run" },

  carts_dir = vim.fn.expand "~/pico8",
  include_file = "main.lua",
  cart_version = 42,

  terminal = {
    -- Run PICO-8 in a terminal buffer inside nvim, so printh() output and
    -- PICO-8's own stdout are visible and the window can be jumped to.
    -- Set false to run detached instead, outliving nvim but with no output.
    enable = true,
    -- Command used to open the window for that buffer.
    split = "botright 15split",
    -- Move the cursor into the terminal on launch.
    focus = false,
    -- Wipe the buffer when PICO-8 exits. Off, so the output stays readable.
    close_on_exit = false,
  },

  lsp = {
    -- Register the bundled PICO-8 API definitions with lua_ls. Set false if
    -- you would rather manage `workspace.library` yourself.
    enable = true,
    -- Attach pico8_ls (github.com/japhib/pico8-ls) to .p8 files if present.
    pico8_ls = true,
    -- Disable diagnostics that fight PICO-8 conventions. PICO-8 code uses
    -- globals deliberately: `local` costs tokens, and the callbacks must be
    -- global for PICO-8 to find them.
    tune_diagnostics = true,
  },

  folding = {
    -- Fold __gfx__/__map__/__sfx__/__music__ closed when opening a .p8.
    enable = true,
    -- Fold them on open rather than leaving them expanded.
    start_closed = true,
  },

  keymaps = {
    -- Set any entry to false to skip it.
    run = "<leader>pr",
    stop = "<leader>ps",
    terminal = "<leader>pt",
    new = false,
    toggle_folds = "<leader>pf",
  },
}

---@type Pico8Config
M.options = vim.deepcopy(defaults)

M.defaults = defaults

---@param opts Pico8Config|nil
function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", vim.deepcopy(defaults), opts or {})

  -- Expand ~ late so users can pass "~/foo" without thinking about it.
  M.options.carts_dir = vim.fn.expand(M.options.carts_dir)

  return M.options
end

return M
