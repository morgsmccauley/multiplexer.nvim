local utils = require('multiplexer.utils')
local log = require('multiplexer.log')

local M = {}

local COMMAND_TIMEOUT_MS = 1000

local function kitty_address()
  if vim.env.KITTY_LISTEN_ON and vim.env.KITTY_LISTEN_ON ~= '' then
    return vim.env.KITTY_LISTEN_ON
  end

  if vim.env.KITTY_PID and vim.env.KITTY_PID ~= '' then
    return 'unix:/tmp/kitty-' .. vim.env.KITTY_PID
  end
end

local function local_socket_path(address)
  local path = address and address:match('^unix:(.+)$')
  if path and path:sub(1, 1) ~= '@' then
    return path
  end
end

function M.is_available()
  return kitty_address() ~= nil
end

local function send_command(args)
  local address = kitty_address()
  if not address then
    log.error('Not running in Kitty terminal')
    vim.notify('multiplexer: Not running in Kitty terminal', vim.log.levels.ERROR)
    return nil
  end

  local socket = local_socket_path(address)
  if socket and not vim.uv.fs_stat(socket) then
    log.error('Kitty remote control socket not found: ', socket)
    vim.notify('multiplexer: Kitty remote control socket not found: ' .. socket, vim.log.levels.WARN)
    return nil
  end

  local cmd = utils.merge_tables({ 'kitty', '@', '--to=' .. address }, args)

  log.info('Running command: ', cmd)

  local ok, result = pcall(function()
    return vim.system(cmd, { text = true, timeout = COMMAND_TIMEOUT_MS }):wait()
  end)

  if not ok then
    log.error('Kitty command failed to start: ', result)
    vim.notify('multiplexer: Failed to run kitty remote control', vim.log.levels.WARN)
    return nil
  end

  if result.code ~= 0 then
    log.error('Kitty command failed: ', cmd, 'Code: ', result.code, 'Stderr: ', result.stderr)
    if result.code == 124 then
      vim.notify('multiplexer: Kitty remote control timed out', vim.log.levels.WARN)
    else
      vim.notify('multiplexer: Kitty remote control failed', vim.log.levels.WARN)
    end
    return nil
  end

  if result.stdout and result.stdout ~= '' then
    local decoded_ok, decoded = pcall(vim.json.decode, result.stdout)
    if not decoded_ok then
      log.error('Failed to parse JSON response: ', result.stdout)
      return nil
    end
    return decoded
  end

  return {}
end

function M.list_windows()
  return send_command({ 'ls' })
end

function M.get_current_tab()
  local all_windows = M.list_windows()

  if not all_windows then
    return nil
  end

  for _, os_window in ipairs(all_windows) do
    if os_window.tabs then
      for _, tab in ipairs(os_window.tabs) do
        if tab.is_focused then
          return tab
        end
      end
    end
  end

  return nil
end

function M.focus_tab(identifier)
  local match = nil

  if identifier.title then
    match = 'title:' .. identifier.title
  elseif identifier.id then
    match = 'id:' .. identifier.id
  end

  return send_command({
    'focus-tab',
    '--match=' .. match
  })
end

function M.launch_tab(args)
  local optional_args = {}

  if args.tab_title then
    table.insert(optional_args, '--tab-title=' .. args.tab_title)
  end

  if args.window_title then
    table.insert(optional_args, '--window-title=' .. args.window_title)
  end

  if args.cwd then
    table.insert(optional_args, '--cwd=' .. args.cwd)
  end

  if args.cmd then
    for _, arg in ipairs(vim.fn.split(args.cmd, ' ')) do
      table.insert(optional_args, arg)
    end
  end

  return send_command(utils.merge_tables(
    {
      'launch',
      '--type=tab'
    },
    optional_args
  ))
end

function M.launch_window(args)
  local optional_args = {}

  if args.title then
    table.insert(optional_args, '--title=' .. args.title)
  end

  if args.cwd then
    table.insert(optional_args, '--cwd=' .. args.cwd)
  end

  if args.env then
    for key, value in pairs(args.env) do
      table.insert(optional_args, '--env=' .. key .. '=' .. value)
    end
  end

  if args.cmd then
    for _, arg in ipairs(vim.fn.split(args.cmd, ' ')) do
      table.insert(optional_args, arg)
    end
  end

  return send_command(utils.merge_tables(
    {
      'launch',
      '--type=window'
    },
    optional_args
  ))
end

function M.focus_window(identifier)
  local match = nil

  if identifier.title then
    match = 'title:' .. identifier.title
  elseif identifier.id then
    match = 'id:' .. identifier.id
  end

  return send_command({
    'focus-window',
    '--match=' .. match
  })
end

function M.close_window(identifier)
  local match = nil

  if identifier.recent then
    match = 'recent:' .. identifier.recent
  elseif identifier.title then
    match = 'title:' .. identifier.title
  elseif identifier.id then
    match = 'id:' .. identifier.id
  end

  return send_command({
    'close-window',
    '--match=' .. match
  })
end

function M.close_tab(identifier)
  local match = nil

  if identifier.title then
    match = 'title:' .. identifier.title
  elseif identifier.id then
    match = 'id:' .. identifier.id
  end

  return send_command({
    'close-tab',
    '--match=' .. match
  })
end

return M
