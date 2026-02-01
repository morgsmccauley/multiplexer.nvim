local Job = require('plenary.job')

local utils = require('multiplexer.utils')
local log = require('multiplexer.log')

local M = {}

function M.is_available()
  return vim.env.KITTY_PID ~= nil
end

local function send_command(args)
  if not vim.env.KITTY_PID then
    log.error('Not running in Kitty terminal')
    vim.notify('multiplexer: Not running in Kitty terminal', vim.log.levels.ERROR)
    return nil
  end

  log.info('Running command: ', args)

  local job = Job:new({
    command = 'kitty',
    args = utils.merge_tables(
      {
        '@',
        '--to=unix:/tmp/kitty-' .. vim.env.KITTY_PID,
      },
      args
    ),
  })

  local raw_results = job:sync()

  if job.code ~= 0 then
    log.error('Kitty command failed: ', args, 'Code: ', job.code)
    vim.notify('multiplexer: Command failed - is remote control enabled?', vim.log.levels.ERROR)
    return nil
  end

  if #raw_results > 0 then
    local ok, result = pcall(vim.json.decode, table.concat(raw_results))
    if not ok then
      log.error('Failed to parse JSON response: ', table.concat(raw_results))
      return nil
    end
    return result
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
