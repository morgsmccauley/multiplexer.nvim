local M = {}

---@class MultiplexerOptions
---@field terminal string
---@field command string
---@field project_paths table
---@field picker string
---@field cache_ttl number
local defaults = {
  terminal = 'auto',
  command = 'nvim',
  session_dir = vim.fn.expand(vim.fn.stdpath('state') .. '/sessions/'),
  session_opts = { 'buffers', 'curdir', 'folds', 'help', 'tabpages', 'winsize', 'localoptions' },
  picker = 'telescope',
  project_paths = {},
  cache_ttl = 30000,
}

---@type MultiplexerOptions
M.options = {}

local function validate_config(opts)
  if opts.terminal and opts.terminal ~= 'auto' and opts.terminal ~= 'kitty' and opts.terminal ~= 'wezterm' then
    vim.notify('multiplexer: Invalid terminal "' .. opts.terminal .. '". Must be "auto", "kitty", or "wezterm"', vim.log.levels.WARN)
    opts.terminal = 'auto'
  end

  if opts.picker and opts.picker ~= 'telescope' and opts.picker ~= 'snacks' then
    vim.notify('multiplexer: Invalid picker "' .. opts.picker .. '". Must be "telescope" or "snacks"', vim.log.levels.WARN)
    opts.picker = 'telescope'
  end

  if opts.project_paths then
    for i, path in ipairs(opts.project_paths) do
      local dir = type(path) == 'table' and path[1] or path
      if type(dir) ~= 'string' then
        vim.notify('multiplexer: Invalid project path at index ' .. i, vim.log.levels.WARN)
      elseif vim.fn.isdirectory(vim.fn.expand(dir)) == 0 then
        vim.notify('multiplexer: Project path does not exist: ' .. dir, vim.log.levels.WARN)
      end
    end
  end

  if opts.cache_ttl and (type(opts.cache_ttl) ~= 'number' or opts.cache_ttl < 0) then
    vim.notify('multiplexer: Invalid cache_ttl. Must be a positive number', vim.log.levels.WARN)
    opts.cache_ttl = defaults.cache_ttl
  end
end

function M.setup(opts)
  opts = opts or {}
  validate_config(opts)
  M.options = vim.tbl_deep_extend('force', {}, defaults, opts)

  if opts.cache_ttl then
    require('multiplexer.cache').set_ttl(opts.cache_ttl)
  end
end

return M
