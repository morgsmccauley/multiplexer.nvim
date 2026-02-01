local Job = require('plenary.job')

local M = {}

function M.merge_tables(table1, table2)
  for _, value in ipairs(table2) do
    table.insert(table1, value)
  end
  return table1
end

function M.find_table_entry(tbl, test_fn)
  local index = 0

  for i, value in ipairs(tbl) do
    if test_fn(value) then
      index = i
      break
    end
  end

  return tbl[index]
end

function M.list_sub_directories(parent_dir, exclude_hidden)
  local args = {
    parent_dir,
    '-maxdepth', '1',
    '-mindepth', '1',
    '-type', 'd'
  }

  if exclude_hidden then
    table.insert(args, '-not')
    table.insert(args, '-name')
    table.insert(args, '.*')
  end

  return Job:new({
    command = 'find',
    args = args,
  }):sync()
end

function M.list_all_sub_directories(path_configs)
  local jobs = {}
  local all_paths = {}

  for i, path_config in ipairs(path_configs) do
    if type(path_config) == 'table' then
      local dir = path_config[1]
      local exclude_hidden = path_config.exclude_hidden

      local args = {
        dir,
        '-maxdepth', '1',
        '-mindepth', '1',
        '-type', 'd'
      }

      if exclude_hidden then
        table.insert(args, '-not')
        table.insert(args, '-name')
        table.insert(args, '.*')
      end

      jobs[i] = Job:new({
        command = 'find',
        args = args,
      })
      jobs[i]:start()
    end
  end

  for i, path_config in ipairs(path_configs) do
    if type(path_config) == 'table' then
      if jobs[i] then
        jobs[i]:wait()
        local results = jobs[i]:result()
        M.merge_tables(all_paths, results)
      end
    else
      table.insert(all_paths, path_config)
    end
  end

  return all_paths
end

return M
