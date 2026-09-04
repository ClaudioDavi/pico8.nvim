local config = require "pico8.config"
local util = require "pico8.util"

local M = {}

--- PICO-8's non-standard operators. lua_ls rejects these as syntax errors
--- unless they are declared here.
M.nonstandard_symbols = {
  "+=",
  "-=",
  "*=",
  "/=",
  "\\=",
  "%=",
  "^=",
  "..=",
  "|=",
  "&=",
  "^^=",
  "<<=",
  ">>=",
  ">>>=",
  "!=",
  "//",
}

--- The lua_ls settings this plugin contributes.
---
--- Exposed so users who configure lua_ls by hand can merge it themselves
--- instead of letting us touch their config:
---
---     local pico8 = require("pico8.lsp").lua_ls_settings()
---     -- merge pico8.Lua into your own settings.Lua
---@return table
function M.lua_ls_settings()
  local opts = config.options

  local settings = {
    Lua = {
      runtime = {
        version = "Lua 5.4",
        nonstandardSymbol = M.nonstandard_symbols,
      },
      workspace = {
        library = { util.types_dir() },
        checkThirdParty = false,
      },
      completion = {
        callSnippet = "Replace",
        keywordSnippet = "Replace",
      },
    },
  }

  if opts.lsp.tune_diagnostics then
    settings.Lua.diagnostics = {
      -- PICO-8 code is global by design: `local` costs tokens against the
      -- 8192 budget, and _init/_update/_draw must be global to be found.
      disable = { "lowercase-global" },
      globals = { "_init", "_update", "_update60", "_draw" },
    }
  end

  return settings
end

--- Merge our settings into an existing lua_ls config table, in place.
---
--- Additive: preserves the user's own library paths, globals and disabled
--- diagnostics rather than replacing them.
---@param existing table|nil
---@return table
function M.extend_lua_ls(existing)
  local ours = M.lua_ls_settings()
  local out = vim.tbl_deep_extend("force", existing or {}, {})

  out.settings = out.settings or {}
  local a, b = out.settings.Lua or {}, ours.Lua

  -- deep_extend replaces list-like tables wholesale, so save the user's own
  -- symbols before merging and concatenate them back afterwards.
  local user_symbols = vim.deepcopy((a.runtime or {}).nonstandardSymbol or {})
  -- One lua_ls client serves every Lua buffer, so its runtime version is not
  -- ours to reassign: a config that already asked for LuaJIT is editing nvim
  -- Lua, and the PICO-8 API comes from types/ either way.
  local user_version = (a.runtime or {}).version
  a.runtime = vim.tbl_deep_extend("force", a.runtime or {}, b.runtime)
  a.runtime.nonstandardSymbol = user_symbols
  a.runtime.version = user_version or a.runtime.version
  for _, sym in ipairs(b.runtime.nonstandardSymbol) do
    if not vim.tbl_contains(a.runtime.nonstandardSymbol, sym) then
      table.insert(a.runtime.nonstandardSymbol, sym)
    end
  end

  a.workspace = a.workspace or {}
  a.workspace.library = a.workspace.library or {}
  for _, path in ipairs(b.workspace.library) do
    if not vim.tbl_contains(a.workspace.library, path) then
      table.insert(a.workspace.library, path)
    end
  end
  if a.workspace.checkThirdParty == nil then
    a.workspace.checkThirdParty = false
  end

  a.completion = vim.tbl_deep_extend("keep", a.completion or {}, b.completion)

  if b.diagnostics then
    a.diagnostics = a.diagnostics or {}
    for _, key in ipairs { "disable", "globals" } do
      a.diagnostics[key] = a.diagnostics[key] or {}
      for _, v in ipairs(b.diagnostics[key]) do
        if not vim.tbl_contains(a.diagnostics[key], v) then
          table.insert(a.diagnostics[key], v)
        end
      end
    end
  end

  out.settings.Lua = a
  return out
end

--- Re-assert our settings on a lua_ls client that is already running.
---
--- Registration order is not something we can control. Anything that calls
--- `vim.lsp.config("lua_ls", ...)` after us wins outright, because that merges
--- with "force" and so replaces list values rather than appending to them --
--- and distros do exactly that: NvChad, for one, registers its own library
--- paths when nvim-lspconfig loads, which lands after a filetype-triggered
--- plugin like this one. The user should not have to reorder their config to
--- work around it, so reconcile as the client attaches: that is the one point
--- guaranteed to run after every registration, whoever made it.
---@param client vim.lsp.Client
local function reconcile(client)
  local merged = M.extend_lua_ls { settings = vim.deepcopy(client.settings or {}) }
  if vim.deep_equal(merged.settings, client.settings) then
    return
  end

  client.settings = merged.settings
  -- 0.11 made the client methods take self; on 0.10 notify is a plain field.
  if vim.fn.has "nvim-0.11" == 1 then
    client:notify("workspace/didChangeConfiguration", { settings = client.settings })
  else
    client.notify("workspace/didChangeConfiguration", { settings = client.settings })
  end
end

--- Wire up the language servers.
---
--- Registers settings up front through `vim.lsp.config` when it exists, and
--- reconciles them onto the live client on every version, so this works whether
--- or not nvim-lspconfig is installed and whatever order a distro sets lua_ls
--- up in.
function M.setup()
  local opts = config.options
  if not opts.lsp.enable then
    return
  end

  local has_new_api = vim.lsp.config ~= nil and vim.fn.has "nvim-0.11" == 1

  if has_new_api then
    -- `vim.lsp.config()` merges with vim.tbl_deep_extend "force", which
    -- *replaces* list-like values instead of appending to them. Handing it our
    -- settings directly would therefore drop any library paths, globals or
    -- disabled rules already registered by a distro or another plugin. Merge
    -- against the existing config ourselves and register the result.
    --
    -- Note the `settings` wrapper -- lua_ls options live under it, not at the
    -- top level of the config table.
    local ok, existing = pcall(function()
      return vim.lsp.config["lua_ls"]
    end)
    local merged = M.extend_lua_ls { settings = vim.deepcopy(ok and existing and existing.settings or {}) }
    vim.lsp.config("lua_ls", { settings = merged.settings })
  end

  -- Registering is not sufficient on its own -- see reconcile().
  vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("pico8_lsp", { clear = true }),
    callback = function(args)
      local client = vim.lsp.get_client_by_id(args.data.client_id)
      if client and client.name == "lua_ls" then
        reconcile(client)
      end
    end,
  })

  -- LspAttach does not fire retroactively, and lua_ls may well be attached
  -- already: this plugin loads on a filetype, so an earlier Lua buffer will
  -- have started it before we were asked for.
  for _, client in ipairs(vim.lsp.get_clients { name = "lua_ls" }) do
    reconcile(client)
  end

  if opts.lsp.pico8_ls and has_new_api then
    -- pico8_ls understands the .p8 container itself (token counts, cart
    -- structure). Only enable it if the binary is actually installed.
    if vim.fn.executable "pico8-ls" == 1 then
      -- Provide a config even if nvim-lspconfig is absent.
      local ok = pcall(function()
        return vim.lsp.config["pico8_ls"]
      end)
      if not ok or vim.lsp.config["pico8_ls"] == nil then
        vim.lsp.config("pico8_ls", {
          cmd = { "pico8-ls", "--stdio" },
          filetypes = { "p8" },
          root_markers = { "*.p8", ".git" },
        })
      end
      vim.lsp.enable "pico8_ls"
    end
  end
end

return M
