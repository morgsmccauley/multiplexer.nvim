local Job = require('plenary.job')

local log = require('multiplexer.log')

local M = {}

function M.is_available()
  return vim.env.WEZTERM_PANE ~= nil
end

local function send_command(args)
  if not vim.env.WEZTERM_PANE then
    log.error('Not running in WezTerm terminal')
    vim.notify('multiplexer: Not running in WezTerm terminal', vim.log.levels.ERROR)
    return nil
  end

  log.info('Running command: ', args)

  local all_args = { 'cli' }
  for _, arg in ipairs(args) do
    table.insert(all_args, arg)
  end

  local job = Job:new({
    command = 'wezterm',
    args = all_args,
  })

  local raw_results = job:sync()

  if job.code ~= 0 then
    log.error('WezTerm command failed: ', args, 'Code: ', job.code)
    vim.notify('multiplexer: WezTerm command failed', vim.log.levels.ERROR)
    return nil
  end

  if #raw_results > 0 then
    local text = table.concat(raw_results, '\n')
    local ok, result = pcall(vim.json.decode, text)
    if not ok then
      return text
    end
    return result
  end

  return {}
end

function M.list_windows()
  local result = send_command({ 'list', '--format', 'json' })
  if not result or type(result) ~= 'table' then
    return nil
  end
  return result
end

function M.get_current_tab()
  local panes = M.list_windows()
  if not panes then
    return nil
  end

  local current_pane_id = tonumber(vim.env.WEZTERM_PANE)

  local windows = {}
  for _, pane in ipairs(panes) do
    table.insert(windows, {
      id = pane.pane_id,
      title = pane.tab_title,
      is_focused = pane.pane_id == current_pane_id,
      cwd = pane.cwd,
    })
  end

  return {
    id = 0,
    is_focused = true,
    windows = windows,
  }
end

function M.focus_tab(identifier)
  local panes = M.list_windows()
  if not panes then
    return nil
  end

  local tab_id = identifier.id
  if identifier.title then
    for _, pane in ipairs(panes) do
      if pane.tab_title == identifier.title then
        tab_id = pane.tab_id
        break
      end
    end
  end

  if tab_id then
    return send_command({ 'activate-tab', '--tab-id', tostring(tab_id) })
  end

  return nil
end

function M.launch_tab(args)
  local cmd_args = { 'spawn' }

  if args.cwd then
    table.insert(cmd_args, '--cwd')
    table.insert(cmd_args, args.cwd)
  end

  if args.cmd then
    table.insert(cmd_args, '--')
    for _, arg in ipairs(vim.fn.split(args.cmd, ' ')) do
      table.insert(cmd_args, arg)
    end
  end

  return send_command(cmd_args)
end

function M.launch_window(args)
  local cmd_args = { 'spawn' }

  if args.cwd then
    table.insert(cmd_args, '--cwd')
    table.insert(cmd_args, args.cwd)
  end

  if args.cmd then
    table.insert(cmd_args, '--')
    for _, arg in ipairs(vim.fn.split(args.cmd, ' ')) do
      table.insert(cmd_args, arg)
    end
  end

  local result = send_command(cmd_args)

  if result and args.title then
    local pane_id = tonumber(result)
    if pane_id then
      vim.defer_fn(function()
        M.set_pane_title(pane_id, args.title)
      end, 100)
    end
  end

  return result
end

function M.set_pane_title(pane_id, title)
  local job = Job:new({
    command = 'wezterm',
    args = { 'cli', 'set-tab-title', '--pane-id', tostring(pane_id), title },
  })
  job:sync()
end

function M.focus_window(identifier)
  local panes = M.list_windows()
  if not panes then
    return nil
  end

  local pane_id = identifier.id
  if identifier.title then
    for _, pane in ipairs(panes) do
      if pane.tab_title == identifier.title then
        pane_id = pane.pane_id
        break
      end
    end
  end

  if pane_id then
    return send_command({ 'activate-pane', '--pane-id', tostring(pane_id) })
  end

  return nil
end

function M.close_window(identifier)
  local panes = M.list_windows()
  if not panes then
    return nil
  end

  local pane_id = identifier.id
  if identifier.title then
    for _, pane in ipairs(panes) do
      if pane.tab_title == identifier.title then
        pane_id = pane.pane_id
        break
      end
    end
  end

  if pane_id then
    return send_command({ 'kill-pane', '--pane-id', tostring(pane_id) })
  end

  return nil
end

function M.close_tab(identifier)
  local panes = M.list_windows()
  if not panes then
    return nil
  end

  local tab_id = identifier.id
  if identifier.title then
    for _, pane in ipairs(panes) do
      if pane.tab_title == identifier.title then
        tab_id = pane.tab_id
        break
      end
    end
  end

  if tab_id then
    for _, pane in ipairs(panes) do
      if pane.tab_id == tab_id then
        send_command({ 'kill-pane', '--pane-id', tostring(pane.pane_id) })
      end
    end
  end

  return {}
end

return M
