local M = {}

function M.check()
  vim.health.start("multiplexer.nvim")

  local backends = require('multiplexer.backends')
  local detected = backends.get_detected_terminal()

  if not detected then
    vim.health.error("No supported terminal detected", {
      "multiplexer.nvim requires running Neovim inside Kitty or WezTerm",
      "Install Kitty: https://sw.kovidgoyal.net/kitty/",
      "Install WezTerm: https://wezfurlong.org/wezterm/"
    })
    return
  end

  vim.health.ok("Detected terminal: " .. detected)

  if detected == 'kitty' then
    M.check_kitty()
  elseif detected == 'wezterm' then
    M.check_wezterm()
  end

  M.check_project_paths()
end

function M.check_kitty()
  local Job = require('plenary.job')
  local result = Job:new({
    command = 'kitty',
    args = { '@', '--to=unix:/tmp/kitty-' .. vim.env.KITTY_PID, 'ls' },
  }):sync()

  if vim.v.shell_error ~= 0 then
    vim.health.error("Kitty remote control not enabled", {
      "Add 'allow_remote_control yes' to your kitty.conf",
      "Or start kitty with: kitty --listen-on=unix:/tmp/kitty"
    })
  else
    vim.health.ok("Kitty remote control is working")
  end
end

function M.check_wezterm()
  local Job = require('plenary.job')
  local job = Job:new({
    command = 'wezterm',
    args = { 'cli', 'list', '--format', 'json' },
  })
  job:sync()

  if job.code ~= 0 then
    vim.health.error("WezTerm CLI not working", {
      "Ensure 'wezterm' is in your PATH",
      "Check WezTerm documentation for CLI setup"
    })
  else
    vim.health.ok("WezTerm CLI is working")
  end
end

function M.check_project_paths()
  local config = require('multiplexer.config')
  if not config.options.project_paths or #config.options.project_paths == 0 then
    vim.health.warn("No project paths configured", {
      "Add project_paths to your setup() call"
    })
  else
    for _, path in ipairs(config.options.project_paths) do
      local dir = type(path) == 'table' and path[1] or path
      if vim.fn.isdirectory(dir) == 0 then
        vim.health.warn("Project path does not exist: " .. dir)
      else
        vim.health.ok("Project path exists: " .. dir)
      end
    end
  end
end

return M
