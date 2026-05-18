local M = {}

local _metadata = {}

function M.set(data)
  _metadata = vim.tbl_extend("force", _metadata, data)
end

function M.get()
  return vim.deepcopy(_metadata)
end

function M.clear()
  _metadata = {}
end

function M.get_all(project_paths)
  local result = {}
  for _, path in ipairs(project_paths) do
    result[path] = {}
  end

  local current_cwd = vim.fn.getcwd()
  result[current_cwd] = M.get()

  return result
end

return M
