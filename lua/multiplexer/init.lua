local config = require('multiplexer.config')
local sessions = require('multiplexer.sessions')

local M = {}

function M.setup(opts)
  config.setup(opts)
  sessions.setup()

  vim.api.nvim_create_user_command('MuxProjects', function()
    M.projects()
  end, { desc = 'Open multiplexer projects picker' })

  vim.api.nvim_create_user_command('MuxProjectsRefresh', function()
    require('multiplexer.projects').refresh()
    vim.notify('multiplexer: Cache refreshed')
  end, { desc = 'Refresh project cache' })

  vim.api.nvim_create_user_command('MuxProjectsCurrent', function()
    local current = require('multiplexer.projects').get_current_project()
    if current then
      vim.notify('Current project: ' .. current.name .. ' (' .. current.path .. ')')
    else
      vim.notify('No current project found')
    end
  end, { desc = 'Show current project info' })
end

function M.projects()
  if config.options.picker == 'snacks' then
    require('snacks._extensions.multiplexer').projects()
  else
    vim.cmd('Telescope multiplexer projects')
  end
end

M.refresh = function()
  return require('multiplexer.projects').refresh()
end

M.get_current_project = function()
  return require('multiplexer.projects').get_current_project()
end

M.list = function()
  return require('multiplexer.projects').list()
end

M.set_metadata = function(data)
  return require('multiplexer.metadata').set(data)
end

M.get_metadata = function()
  return require('multiplexer.metadata').get()
end

M.clear_metadata = function()
  return require('multiplexer.metadata').clear()
end

return M
