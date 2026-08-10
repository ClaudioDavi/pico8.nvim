local M = {}

--- Root of this plugin on disk, so we can point lua_ls at `types/`.
---@return string
function M.plugin_root()
  local source = debug.getinfo(1, "S").source:sub(2)
  -- .../lua/pico8/util.lua -> .../
  return vim.fn.fnamemodify(source, ":h:h:h")
end

--- Directory holding the bundled API definitions.
---@return string
function M.types_dir()
  return M.plugin_root() .. "/types"
end

---@param msg string
---@param level integer|nil
function M.notify(msg, level)
  vim.notify(msg, level or vim.log.levels.INFO, { title = "pico8" })
end

--- Find the .p8 cart associated with a buffer.
---
--- A .p8 buffer is its own cart. For a .lua buffer we walk up from the file
--- looking for a sibling cart, so `<leader>pr` works while editing main.lua.
--- If several carts sit in one directory we cannot know which is meant, so
--- return them all and let the caller decide.
---@param bufnr integer|nil
---@return string[] carts Absolute paths, nearest directory first.
function M.find_carts(bufnr)
  bufnr = bufnr or 0
  local name = vim.api.nvim_buf_get_name(bufnr)
  if name == "" then
    return {}
  end

  if name:match "%.p8$" then
    return { name }
  end

  local dir = vim.fn.fnamemodify(name, ":h")
  local prev = nil
  -- Walk up a bounded number of levels; stop at the filesystem root.
  while dir ~= prev do
    local found = vim.fn.glob(dir .. "/*.p8", false, true)
    if #found > 0 then
      table.sort(found)
      return found
    end
    prev = dir
    dir = vim.fn.fnamemodify(dir, ":h")
  end

  return {}
end

--- True if `cart` delegates its code to an #include.
---@param cart string
---@return boolean
---@return string|nil included Name of the included file, if any.
function M.cart_uses_include(cart)
  local ok, lines = pcall(vim.fn.readfile, cart, "", 40)
  if not ok or type(lines) ~= "table" then
    return false, nil
  end
  for _, line in ipairs(lines) do
    local inc = line:match "^#include%s+(%S+)"
    if inc then
      return true, inc
    end
  end
  return false, nil
end

return M
