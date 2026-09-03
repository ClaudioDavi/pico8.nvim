local config = require "pico8.config"
local util = require "pico8.util"

local M = {}

--- What we started, and where its output went.
---
--- Only one of `proc` (detached run) and `job` (terminal run) is ever set.
local state = {
  ---@type vim.SystemObj|nil
  proc = nil,
  ---@type integer|nil
  job = nil,
  ---@type integer|nil
  bufnr = nil,
  --- True while an exit we asked for is in flight, so it is not reported as a
  --- crash. A killed pty job's status depends on the signal PICO-8 handles.
  stopping = false,
}

--- Window currently displaying `bufnr`, if any.
---@param bufnr integer
---@return integer|nil
local function window_for(bufnr)
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_get_buf(win) == bufnr then
      return win
    end
  end
end

--- Show a buffer in the configured split, without stealing the cursor unless
--- asked to.
---@param bufnr integer
---@return integer win
local function show(bufnr)
  local existing = window_for(bufnr)
  if existing then
    return existing
  end

  local opts = config.options.terminal
  local prev = vim.api.nvim_get_current_win()

  vim.cmd(opts.split)
  local win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(win, bufnr)

  -- Line numbers and signs on a log of printh() output are only noise.
  vim.wo[win].number = false
  vim.wo[win].relativenumber = false
  vim.wo[win].signcolumn = "no"

  if opts.focus then
    vim.cmd "startinsert"
  else
    vim.api.nvim_set_current_win(prev)
  end

  return win
end

--- termopen() is deprecated from 0.11 on, where jobstart({ term = true }) is
--- the supported spelling. Both need the target buffer to be current.
---@param cmd string[]
---@param opts table
---@return integer job
local function termopen(cmd, opts)
  if vim.fn.has "nvim-0.11" == 1 then
    return vim.fn.jobstart(cmd, vim.tbl_extend("force", opts, { term = true }))
  end
  ---@diagnostic disable-next-line: deprecated
  return vim.fn.termopen(cmd, opts)
end

--- Report a non-clean exit. 143 is SIGTERM, i.e. our own :Pico8Stop.
---@param code integer
---@param extra string|nil
local function report_exit(code, extra)
  if code == 0 or code == 143 or state.stopping then
    state.stopping = false
    return
  end
  extra = (extra or ""):gsub("%s+$", "")
  util.notify(("PICO-8 exited with %d%s"):format(code, extra ~= "" and ": " .. extra or ""), vim.log.levels.WARN)
end

--- Run in a terminal buffer inside nvim, so printh() output and PICO-8's own
--- stdout are readable and the window is just another window to jump to.
---
--- Unlike the detached path, PICO-8 dies with nvim: the job owns the pty.
---@param cmd string[]
local function run_in_terminal(cmd)
  local opts = config.options.terminal

  -- A previous run still holding the buffer would leave two PICO-8s fighting
  -- over one window, so retire it first.
  local old = state.bufnr
  if state.job then
    state.stopping = true
    vim.fn.jobstop(state.job)
    state.job = nil
  end

  local bufnr = vim.api.nvim_create_buf(false, true)
  state.bufnr = bufnr
  local win = show(bufnr)

  if old and vim.api.nvim_buf_is_valid(old) then
    vim.api.nvim_buf_delete(old, { force = true })
  end

  vim.api.nvim_win_call(win, function()
    state.job = termopen(cmd, {
      -- The exit of a job we already replaced arrives after the new one has
      -- started, so everything here is scoped to the job that is exiting.
      on_exit = function(id, code)
        if state.job == id then
          state.job = nil
        end
        report_exit(code)
        if opts.close_on_exit and vim.api.nvim_buf_is_valid(bufnr) then
          vim.api.nvim_buf_delete(bufnr, { force = true })
          if state.bufnr == bufnr then
            state.bufnr = nil
          end
        end
      end,
    })
  end)

  if state.job <= 0 then
    util.notify(("could not start %q"):format(cmd[1]), vim.log.levels.ERROR)
    state.job = nil
  end
end

--- Run detached, so nvim never blocks and PICO-8 outlives the editor.
---@param cmd string[]
local function run_detached(cmd)
  state.proc = vim.system(cmd, { detach = true }, function(res)
    vim.schedule(function()
      report_exit(res.code, res.stderr)
    end)
  end)
end

--- Launch PICO-8 on a cart.
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

  if opts.terminal.enable then
    run_in_terminal(cmd)
  else
    run_detached(cmd)
  end

  util.notify("running " .. vim.fn.fnamemodify(cart, ":t"))
end

--- Terminate the PICO-8 process we launched.
function M.stop()
  if state.job then
    state.stopping = true
    vim.fn.jobstop(state.job)
    state.job = nil
  elseif state.proc then
    state.proc:kill "sigterm"
    state.proc = nil
  else
    util.notify("no PICO-8 process started from nvim", vim.log.levels.WARN)
    return
  end
  util.notify "stopped PICO-8"
end

--- Drop the accumulated output, leaving PICO-8 running.
---
--- Terminal buffers are not editable, so the way to discard scrollback is to
--- trim 'scrollback' and put it back. The terminal's live screen is not
--- scrollback and survives; only history above it goes.
function M.clear_terminal()
  local bufnr = state.bufnr
  if not (bufnr and vim.api.nvim_buf_is_valid(bufnr) and vim.bo[bufnr].buftype == "terminal") then
    util.notify("no PICO-8 terminal; run a cart first", vim.log.levels.WARN)
    return
  end

  local keep = vim.bo[bufnr].scrollback
  vim.bo[bufnr].scrollback = 1
  vim.schedule(function()
    if vim.api.nvim_buf_is_valid(bufnr) then
      vim.bo[bufnr].scrollback = keep
    end
  end)
end

--- Show or hide the run terminal, leaving PICO-8 alone either way.
function M.toggle_terminal()
  if not (state.bufnr and vim.api.nvim_buf_is_valid(state.bufnr)) then
    util.notify("no PICO-8 terminal; run a cart first", vim.log.levels.WARN)
    return
  end

  local win = window_for(state.bufnr)
  if win then
    vim.api.nvim_win_close(win, false)
  else
    show(state.bufnr)
  end
end

return M
