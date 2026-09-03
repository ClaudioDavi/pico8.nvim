-- Minimal config to test pico8.nvim in isolation: no plugin manager, no distro.
--
--   nvim --clean -u test/minimal_init.lua some.p8
--
-- Everything below is stock nvim plus this plugin.

local root = vim.fn.fnamemodify(vim.fn.resolve(vim.fn.expand "<sfile>:p"), ":h:h")

vim.opt.runtimepath:prepend(root)
vim.opt.swapfile = false

-- <leader> is resolved when a mapping is defined, so this has to be set before
-- setup(). Space matches most configs; --clean would otherwise leave it as "\".
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- lua_ls, if installed, so completion can be exercised.
if vim.fn.executable "lua-language-server" == 1 and vim.lsp.config then
  vim.lsp.config("lua_ls", {
    cmd = { "lua-language-server" },
    filetypes = { "lua" },
    root_markers = { ".luarc.json", ".git" },
  })
  vim.lsp.enable "lua_ls"
end

require("pico8").setup {
  carts_dir = vim.fn.expand "~/pico8-test",
}
