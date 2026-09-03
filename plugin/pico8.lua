-- User commands are registered eagerly so they exist before setup() runs;
-- the heavier modules are only required when a command is actually used.
if vim.g.loaded_pico8 then
  return
end
vim.g.loaded_pico8 = true

vim.api.nvim_create_user_command("Pico8Run", function(cmd)
  require("pico8.run").run(cmd.args ~= "" and vim.fn.expand(cmd.args) or nil)
end, { nargs = "?", complete = "file", desc = "Run a PICO-8 cart" })

vim.api.nvim_create_user_command("Pico8Stop", function()
  require("pico8.run").stop()
end, { desc = "Stop the PICO-8 process started from nvim" })

vim.api.nvim_create_user_command("Pico8Term", function()
  require("pico8.run").toggle_terminal()
end, { desc = "Show or hide the PICO-8 run terminal" })

vim.api.nvim_create_user_command("Pico8TermClear", function()
  require("pico8.run").clear_terminal()
end, { desc = "Discard the PICO-8 terminal's output, leaving it running" })

vim.api.nvim_create_user_command("Pico8New", function(cmd)
  local name = cmd.args
  if name == "" then
    name = vim.fn.input "cart name: "
    if name == "" then
      return
    end
  end
  local cart = require("pico8.cart").new(name)
  if cart then
    local include = vim.fn.fnamemodify(cart, ":h") .. "/" .. require("pico8.config").options.include_file
    vim.cmd.edit(include)
  end
end, { nargs = "?", desc = "Scaffold a new PICO-8 cart" })

vim.api.nvim_create_user_command("Pico8Info", function()
  require("pico8.health").info()
end, { desc = "Show pico8.nvim paths and detected tools" })
