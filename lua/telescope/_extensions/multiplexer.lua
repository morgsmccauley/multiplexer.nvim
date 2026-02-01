local telescope = require('telescope')
local actions = require 'telescope.actions'
local action_state = require 'telescope.actions.state'
local pickers = require 'telescope.pickers'
local entry_display = require('telescope.pickers.entry_display')
local finders = require 'telescope.finders'
local conf = require('telescope.config').values

local mux_projects = require('multiplexer.projects')

local list_projects = function(opts)
  opts = opts or {}

  local make_finder = function()
    local projects = mux_projects.list()

    local max_width = 0
    for _, project in ipairs(projects) do
      if #project.name > max_width then
        max_width = #project.name
      end
    end

    local displayer = entry_display.create {
      separator = " ",
      items = {
        { width = 2 },
        { width = max_width },
        { remaining = true },
      },
    }

    return finders.new_table(
      {
        results = projects,
        entry_maker = function(project)
          local indicator = ''
          if project.open and project.is_focused then
            indicator = '%a'
          elseif project.open and project.was_focused then
            indicator = '#a'
          elseif project.open then
            indicator = 'a'
          end

          return {
            value = project,
            ordinal = project.name,
            display = function()
              return displayer({
                indicator,
                project.name,
                { vim.fn.fnamemodify(project.path, ':~'), 'TelescopeResultsComment' }
              })
            end
          }
        end,
      })
  end

  pickers.new(opts, {
    prompt_title = 'Projects',
    finder = make_finder(),
    sorter = conf.generic_sorter(opts),
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        local project = selection.value

        mux_projects.switch(project)
      end)

      local function close_project()
        local selection = action_state.get_selected_entry()
        local project = selection.value

        mux_projects.close(project)

        local current_picker = action_state.get_current_picker(prompt_bufnr)
        current_picker:refresh(make_finder())
      end

      map('i', '<C-x>', close_project)

      local function restart_project()
        local selection = action_state.get_selected_entry()
        local project = selection.value

        actions.close(prompt_bufnr)
        mux_projects.restart(project)
      end

      map('i', '<C-r>', restart_project)

      return true
    end,
  }):find()
end

return telescope.register_extension({
  exports = {
    projects = list_projects
  }
})
