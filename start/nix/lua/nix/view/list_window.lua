---@class NixTemplateAdapter
---@field config? table                          -- optional override config
---@field get_all_items? fun(cb:function)        -- async (preferred) or sync provider: if cb passed call it with list, else return list
---@field get_checked_items? fun(cb:function)    -- async (preferred) or sync provider
---@field on_check? fun(item:string, done:function)  -- MUST call done() when finished (async)
---@field on_uncheck? fun(item:string, done:function) -- MUST call done() when finished (async)
---@field check_function? fun(item:string):boolean|nil -- dynamic check state (read-only)
---@field on_open? fun(self:NixTemplate, done:function) -- optional hook executed before first render, call done() when ready

---@class NixTemplate
---@field state table
---@field config table
---@field get_items_all fun(cb:function)|nil
---@field get_items_checked fun(cb:function)|nil
---@field on_check fun(item:string, done:function)
---@field on_uncheck fun(item:string, done:function)
---@field check_function fun(item:string):boolean|nil
local Adapter = {}
Adapter.__index = Adapter

-- Default configuration
local DEFAULT_CONFIG = {
  width = 0.4,
  height = 0.4,
  border = { "", " ", "", "", "", "", "", "" },
  title = "Nix UI Template",
  sort = {
    checked_first = true,
    case_insensitive = true,
    -- custom comparator receives (a, b, checked_set) return boolean|nil
    comparator = nil,
  },
  debounce = 30, -- ms for batched updates
  icons = {
    checked = "◼",
    unchecked = "◻",
    pending_frames = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }, -- spinner
    pending = "…", -- fallback if spinner disabled
  },
  spinner_interval = 80, -- ms
  keys = {
    check = { "i" },
    uncheck = { "u" },
    toggle = { "<CR>" },
    sort = { "s" },
    help = { "?" },
    refresh = { "r" },
    close = { "q", "<Esc>" },
  },
  highlights = {
    checked = "NixTemplateChecked",
    unchecked = "NixTemplateUnchecked",
    pending = "NixTemplatePending",
    title = "NixTemplateTitle",
  },
  concurrency = 2,            -- how many async actions at once
  allow_repeat_queue = false, -- if false, repeated action for same item ignored while pending
  show_pending_after = 80,    -- ms threshold before showing spinner (prevents flash for very quick ops)
}

-- Utility: simple deep merge
local function deep_merge(dst, src)
  for k, v in pairs(src) do
    if type(v) == "table" and type(dst[k]) == "table" then
      deep_merge(dst[k], v)
    else
      dst[k] = v
    end
  end
  return dst
end

---Create a new NixTemplate instance
---@param adapter NixTemplateAdapter
---@return NixTemplate
function Adapter:new(adapter)
  self = setmetatable({}, self)

  self.state = {
    buf = nil,
    win = nil,
    help_buf = nil,
    help_win = nil,
    items_all = {},
    items_checked = {},
    pending = {}, -- [item] = { action="check"/"uncheck", start=hrtime, frame=1, timer, show=false }
    queue = {},   -- queued jobs { item=item, action="check"/"uncheck" }
    active_jobs = 0,
    closing = false,
    last_update_req = 0,
    scheduled_update = false,
    applied_hl_ns = nil,
  }

  self.config = deep_merge(vim.deepcopy(DEFAULT_CONFIG), adapter.config or {})

  self.get_items_all = adapter.get_all_items
  self.get_items_checked = adapter.get_checked_items
  self.check_function = adapter.check_function

  self.on_check = adapter.on_check
      or function(item, done)
        -- Example async simulation
        vim.defer_fn(function()
          done()
        end, 120)
      end

  self.on_uncheck = adapter.on_uncheck or function(item, done)
    vim.defer_fn(function()
      done()
    end, 120)
  end

  self.on_open = adapter.on_open

  return self
end

-----------------------------------------------------------------------
-- Rendering / Windows
-----------------------------------------------------------------------
function Adapter:create_floating_window()
  local width = math.floor(vim.o.columns * self.config.width)
  local height = math.floor(vim.o.lines * self.config.height)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  if not self.state.buf or not vim.api.nvim_buf_is_valid(self.state.buf) then
    self.state.buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = self.state.buf })
    vim.api.nvim_set_option_value("filetype", "nix-template", { buf = self.state.buf })
  end

  local win_conf = {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = self.config.border,
    title = self.config.title,
    title_pos = "center",
  }

  self.state.win = vim.api.nvim_open_win(self.state.buf, true, win_conf)
  self:_ensure_highlights()

  -- Set window options (like number, cursorline, etc)
  local winopts = {
    cursorline = true,
    wrap = false,
    foldcolumn = "0",
    signcolumn = "no",
    colorcolumn = "",
    number = false,
    relativenumber = false,
  }
  for k, v in pairs(winopts) do
    vim.api.nvim_set_option_value(k, v, { win = self.state.win })
  end

  return self.state.win
end

-- Ensure highlight groups exist (if user hasn't defined)
function Adapter:_ensure_highlights()
  if self.state.applied_hl_ns then
    return
  end
  local ns = vim.api.nvim_create_namespace("nix_template_hl")
  self.state.applied_hl_ns = ns

  local function link(name, target, default)
    if vim.fn.hlexists(name) == 0 then
      if target then
        vim.api.nvim_set_hl(0, name, { link = target })
      else
        vim.api.nvim_set_hl(0, name, default or { fg = "#aaaaaa" })
      end
    end
  end

  link(self.config.highlights.title, "Title", { bold = true })
end

---Update the buffer contents to reflect checked/unchecked items
---@param opts table|nil Options, e.g. { sort = true, force = false }
function Adapter:update(opts)
  opts = opts or {}
  if self.state.closing then
    return
  end
  if not (self.state.buf and vim.api.nvim_buf_is_valid(self.state.buf)) then
    return
  end

  local items_all = self.state.items_all
  local checked_list = self.state.items_checked
  local checked_set = {}
  for _, it in ipairs(checked_list) do
    checked_set[it] = true
  end

  if opts.sort ~= false then
    local cfg_sort = self.config.sort
    local cmp = cfg_sort.comparator
    table.sort(items_all, function(a, b)
      if cmp then
        local ok, res = pcall(cmp, a, b, checked_set)
        if ok and res ~= nil then
          return res
        end
      end
      local ac = checked_set[a] or false
      local bc = checked_set[b] or false
      if cfg_sort.checked_first and ac ~= bc then
        return ac
      end
      if cfg_sort.case_insensitive then
        a = a:lower()
        b = b:lower()
      end
      return a < b
    end)
  end

  local frames = self.config.icons.pending_frames or {}
  local lines = {}
  local line_meta = {} -- for applying highlights: { {idx=, hl=, col_start, col_end} }
  for _, item in ipairs(items_all) do
    local dyn_checked = (self.check_function and self.check_function(item))
    local is_checked = dyn_checked == nil and checked_set[item] or dyn_checked

    local pending = self.state.pending[item]
    local icon
    if pending and pending.show then
      if #frames > 0 then
        icon = frames[pending.frame] or frames[1]
      else
        icon = self.config.icons.pending
      end
    else
      icon = is_checked and self.config.icons.checked or self.config.icons.unchecked
    end
    local line = string.format(" %s %s", icon, item)
    lines[#lines + 1] = line
    local hl_group
    if pending and pending.show then
      hl_group = self.config.highlights.pending
    else
      hl_group = is_checked and self.config.highlights.checked or self.config.highlights.unchecked
    end
    line_meta[#line_meta + 1] = { index = #lines, hl = hl_group, col_start = 0, col_end = #icon }
  end

  vim.api.nvim_set_option_value("modifiable", true, { buf = self.state.buf })
  vim.api.nvim_buf_set_lines(self.state.buf, 0, -1, false, lines)
  vim.api.nvim_set_option_value("modifiable", false, { buf = self.state.buf })

  -- Clear ns and re-apply highlights
  if self.state.applied_hl_ns then
    vim.api.nvim_buf_clear_namespace(self.state.buf, self.state.applied_hl_ns, 0, -1)
    for _, m in ipairs(line_meta) do
      pcall(vim.api.nvim_buf_set_extmark, self.state.buf, self.state.applied_hl_ns, m.index - 1, m.col_start, {
        end_col = m.col_end,
        hl_group = m.hl,
      })
    end
  end
end

---Get the item at the current cursor position
---@return string|nil item Item name or nil
function Adapter:item_at_cursor()
  if not (self.state.win and vim.api.nvim_win_is_valid(self.state.win)) then
    return nil
  end
  local cur = vim.api.nvim_win_get_cursor(self.state.win)
  local line = vim.api.nvim_buf_get_lines(self.state.buf, cur[1] - 1, cur[1], false)[1]
  if not line then
    return nil
  end
  -- remove whitespaces and icon
  local item = line:match("^%s*[%S]+%s+(.*)$")
  return item and vim.trim(item) or nil
end

-----------------------------------------------------------------------
-- Help window
-----------------------------------------------------------------------
function Adapter:help()
  if self.state.help_win and vim.api.nvim_win_is_valid(self.state.help_win) then
    vim.api.nvim_set_current_win(self.state.help_win)
    return
  end

  if not (self.state.help_buf and vim.api.nvim_buf_is_valid(self.state.help_buf)) then
    self.state.help_buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = self.state.help_buf })
    vim.api.nvim_set_option_value("filetype", "nix-template-help", { buf = self.state.help_buf })
  end

  local cfg = {
    width = 0.5,
    height = 0.5,
    border = "rounded",
    title = "Help",
  }

  local width = math.floor(vim.o.columns * cfg.width)
  local height = math.floor(vim.o.lines * cfg.height)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  local win_conf = {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = cfg.border,
    title = cfg.title,
    title_pos = "center",
  }

  self.state.help_win = vim.api.nvim_open_win(self.state.help_buf, true, win_conf)

  local help_close_keys = { "q", "<Esc>" }
  local lines = { "Keybindings:" }
  for action, keys in pairs(self.config.keys or {}) do
    local list = type(keys) == "table" and keys or { keys }
    local key_str = table.concat(list, ", ")
    local padding = string.rep(" ", math.max(0, 10 - #key_str))
    lines[#lines + 1] = string.format("  %s%s  %s", key_str, padding, action)
  end
  lines[#lines + 1] = ""
  lines[#lines + 1] = string.format("Press '%s' to close help.", table.concat(help_close_keys, "' or '"))

  vim.api.nvim_set_option_value("modifiable", true, { buf = self.state.help_buf })
  vim.api.nvim_buf_set_lines(self.state.help_buf, 0, -1, false, lines)
  vim.api.nvim_set_option_value("modifiable", false, { buf = self.state.help_buf })

  for _, k in ipairs(help_close_keys) do
    vim.keymap.set("n", k, function()
      if self.state.help_win and vim.api.nvim_win_is_valid(self.state.help_win) then
        vim.api.nvim_win_close(self.state.help_win, true)
        self.state.help_win = nil
      end
    end, { buffer = self.state.help_buf, noremap = true, silent = true })
  end
end

-----------------------------------------------------------------------
-- Async job queue & spinner
-----------------------------------------------------------------------
-- Debounced update wrapper
function Adapter:_debounced_update(opts)
  opts = opts or {}
  local now = vim.loop.hrtime() / 1e6
  self.state.last_update_req = now
  if self.state.scheduled_update then
    return
  end
  self.state.scheduled_update = true
  vim.defer_fn(function()
    self.state.scheduled_update = false
    self:update(opts)
  end, self.config.debounce)
end

function Adapter:_start_spinner()
  if self._spinner_active then
    return
  end
  self._spinner_active = true
  local function tick()
    if self.state.closing then
      self._spinner_active = false
      return
    end
    local any = false
    for item, meta in pairs(self.state.pending) do
      any = true
      -- Only start showing spinner after threshold
      local elapsed = (vim.loop.hrtime() - meta.start) / 1e6
      if not meta.show and elapsed >= self.config.show_pending_after then
        meta.show = true
      end
      if meta.show then
        meta.frame = ((meta.frame or 1) % #self.config.icons.pending_frames) + 1
      end
    end
    if any then
      self:_debounced_update({ sort = false })
      vim.defer_fn(tick, self.config.spinner_interval)
    else
      self._spinner_active = false
    end
  end
  vim.defer_fn(tick, self.config.spinner_interval)
end

function Adapter:_enqueue_action(item, action)
  -- action: "check" | "uncheck"
  -- Avoid duplicating if already pending or queued (unless allowed)
  if not self.config.allow_repeat_queue then
    if self.state.pending[item] then
      return
    end
    for _, q in ipairs(self.state.queue) do
      if q.item == item then
        return
      end
    end
  end
  table.insert(self.state.queue, { item = item, action = action })
  self:_process_queue()
end

function Adapter:_process_queue()
  if self.state.closing then
    return
  end
  while self.state.active_jobs < self.config.concurrency and #self.state.queue > 0 do
    local job = table.remove(self.state.queue, 1)
    self:_run_job(job.item, job.action)
  end
end

function Adapter:_run_job(item, action)
  local callback
  if action == "check" then
    callback = self.on_check
  else
    callback = self.on_uncheck
  end
  self.state.active_jobs = self.state.active_jobs + 1
  self.state.pending[item] = {
    action = action,
    start = vim.loop.hrtime(),
    frame = 1,
    show = false,
  }
  self:_start_spinner()

  local function done()
    if self.state.closing then
      return
    end
    local pending = self.state.pending[item]
    if pending then
      self.state.pending[item] = nil
    end
    -- Mutate checked list only if not overridden by dynamic check_function
    if not self.check_function then
      if action == "check" then
        local present = false
        for _, v in ipairs(self.state.items_checked) do
          if v == item then
            present = true
            break
          end
        end
        if not present then
          table.insert(self.state.items_checked, item)
        end
      else
        local new = {}
        for _, v in ipairs(self.state.items_checked) do
          if v ~= item then
            new[#new + 1] = v
          end
        end
        self.state.items_checked = new
      end
    end
    self.state.active_jobs = self.state.active_jobs - 1
    self:_debounced_update({ sort = true })
    self:_process_queue()
  end

  local ok, err = pcall(callback, item, function()
    vim.schedule(done)
  end)
  if not ok then
    vim.notify(string.format("NixTemplate %s error for '%s': %s", action, item, err), vim.log.levels.ERROR)
    done()
  end
end

-----------------------------------------------------------------------
-- User actions
-----------------------------------------------------------------------
function Adapter:check()
  local item = self:item_at_cursor()
  if not item then
    return
  end
  local set = {}
  for _, v in ipairs(self.state.items_checked) do
    set[v] = true
  end
  if self.check_function and self.check_function(item) then
    return
  end
  if not set[item] then
    self:_enqueue_action(item, "check")
  end
end

function Adapter:uncheck()
  local item = self:item_at_cursor()
  if not item then
    return
  end
  local set = {}
  for _, v in ipairs(self.state.items_checked) do
    set[v] = true
  end
  if self.check_function and not self.check_function(item) then
    return
  end
  if set[item] then
    self:_enqueue_action(item, "uncheck")
  end
end

function Adapter:toggle()
  local item = self:item_at_cursor()
  if not item then
    return
  end
  local set = {}
  for _, v in ipairs(self.state.items_checked) do
    set[v] = true
  end
  if self.check_function then
    if self.check_function(item) then
      self:uncheck()
    else
      self:check()
    end
  else
    if set[item] then
      self:uncheck()
    else
      self:check()
    end
  end
end

function Adapter:refresh()
  self:load_items(function()
    self:update({ sort = true, force = true })
  end)
end

-----------------------------------------------------------------------
-- Data loading
-----------------------------------------------------------------------
function Adapter:_invoke_provider(fn, fallback, cb)
  if not fn then
    cb(fallback)
    return
  end
  -- If provider expects callback
  local ok, res = pcall(function()
    return fn(function(list)
      cb(list or {})
    end)
  end)
  if not ok then
    vim.notify("NixTemplate provider error: " .. res, vim.log.levels.ERROR)
    cb(fallback)
    return
  end
  -- If provider returned a list synchronously
  if type(res) == "table" then
    cb(res)
  elseif res == nil then
    -- async; callback will handle
  else
    cb(fallback)
  end
end

function Adapter:load_items(done)
  done = done or function() end
  local remaining = 2
  local function one_done()
    remaining = remaining - 1
    if remaining == 0 then
      done()
    end
  end
  self:_invoke_provider(self.get_items_all, {}, function(list)
    self.state.items_all = list or {}
    one_done()
  end)
  self:_invoke_provider(self.get_items_checked, {}, function(list)
    self.state.items_checked = list or {}
    one_done()
  end)
end

-----------------------------------------------------------------------
-- Keybindings
-----------------------------------------------------------------------
function Adapter:set_keybindings()
  local function map(keys, fn, desc)
    if not keys then
      return
    end
    for _, k in ipairs(type(keys) == "table" and keys or { keys }) do
      vim.keymap.set("n", k, fn, {
        buffer = self.state.buf,
        noremap = true,
        silent = true,
        nowait = true,
        desc = desc,
      })
    end
  end

  map(self.config.keys.check, function()
    self:check()
  end, "Check")
  map(self.config.keys.uncheck, function()
    self:uncheck()
  end, "Uncheck")
  map(self.config.keys.toggle, function()
    self:toggle()
  end, "Toggle")
  map(self.config.keys.sort, function()
    self:update({ sort = true })
  end, "Sort")
  map(self.config.keys.help, function()
    self:help()
  end, "Help")
  map(self.config.keys.refresh, function()
    self:refresh()
  end, "Refresh")
  map(self.config.keys.close, function()
    self:close()
  end, "Close")
end

-----------------------------------------------------------------------
-- Lifecycle
-----------------------------------------------------------------------
function Adapter:open()
  if self.state.win and vim.api.nvim_win_is_valid(self.state.win) then
    vim.api.nvim_set_current_win(self.state.win)
    return
  end

  self:create_floating_window()
  self:set_keybindings()

  local function after_initial()
    self:update({ sort = true })
  end

  if self.on_open then
    local done_called = false
    local function done()
      if done_called then
        return
      end
      done_called = true
      self:load_items(after_initial)
    end
    local ok, err = pcall(self.on_open, self, done)
    if not ok then
      vim.notify("NixTemplate on_open error: " .. err, vim.log.levels.ERROR)
      self:load_items(after_initial)
    end
  else
    self:load_items(after_initial)
  end
end

function Adapter:close()
  self.state.closing = true
  -- clear timers/spinner
  self.state.pending = {}
  self.state.queue = {}
  if self.state.help_win and vim.api.nvim_win_is_valid(self.state.help_win) then
    vim.api.nvim_win_close(self.state.help_win, true)
  end
  if self.state.win and vim.api.nvim_win_is_valid(self.state.win) then
    vim.api.nvim_win_close(self.state.win, true)
  end
  if self.state.buf and vim.api.nvim_buf_is_valid(self.state.buf) then
    vim.api.nvim_buf_delete(self.state.buf, { force = true })
  end
  if self.state.help_buf and vim.api.nvim_buf_is_valid(self.state.help_buf) then
    vim.api.nvim_buf_delete(self.state.help_buf, { force = true })
  end
  self.state.win = nil
  self.state.buf = nil
  self.state.help_win = nil
  self.state.help_buf = nil
end

return Adapter
