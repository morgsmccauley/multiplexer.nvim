local mux_projects = require('multiplexer.projects')

local M = {}

local function format_metadata(meta)
  local parts = {}
  for k, v in pairs(meta) do
    table.insert(parts, k .. ": " .. tostring(v))
  end
  return table.concat(parts, "  ")
end

function M.projects(opts)
  opts = opts or {}

  local projects = mux_projects.list()

  local max_name_width = 0
  local max_meta_width = 0
  for _, project in ipairs(projects) do
    if #project.name > max_name_width then
      max_name_width = #project.name
    end
    local meta_str = format_metadata(project.metadata)
    if #meta_str > max_meta_width then
      max_meta_width = #meta_str
    end
  end

  local items = {}
  for _, project in ipairs(projects) do
    local indicator = ''
    if project.open and project.is_focused then
      indicator = '%a'
    elseif project.open and project.was_focused then
      indicator = '#a'
    elseif project.open then
      indicator = 'a'
    else
      indicator = ''
    end

    local meta_str = format_metadata(project.metadata)

    table.insert(items, {
      text = project.name,
      indicator = indicator,
      project = project,
      buf = '',
      path = vim.fn.fnamemodify(project.path, ':~'),
      meta = meta_str,
      max_name_width = max_name_width,
      max_meta_width = max_meta_width
    })
  end

  require('snacks').picker.pick('multiplexer_projects', vim.tbl_deep_extend('force', {
    title = 'Projects',
    items = items,
    layout = { preset = "ivy", preview = false },
    format = function(item)
      local indicator_col = string.format("%-2s", item.indicator)
      local name_col = string.format("%-" .. item.max_name_width .. "s", item.text)
      local meta_col = item.max_meta_width > 0 and string.format("%-" .. item.max_meta_width .. "s", item.meta) or ""
      local path_col = item.path

      local result = {
        { indicator_col },
        { " " .. name_col },
      }
      if item.max_meta_width > 0 then
        table.insert(result, { " " .. meta_col, 'Comment' })
      end
      table.insert(result, { " " .. path_col, 'TelescopeResultsComment' })
      return result
    end,
    confirm = function(picker, item)
      picker:close()
      mux_projects.switch(item.project)
    end,
    win = {
      input = {
        keys = {
          ['<C-x>'] = { 'close', mode = { 'i', 'n' } },
          ['<C-r>'] = { 'restart', mode = { 'i', 'n' } },
        }
      }
    },
    actions = {
      close = function(picker, item)
        picker:close()
        mux_projects.close(item.project)
      end,
      restart = function(picker, item)
        picker:close()
        mux_projects.restart(item.project)
      end
    },
  }, opts))
end

return M
