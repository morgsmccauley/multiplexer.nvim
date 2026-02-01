local Path = require('plenary.path')

local M = {}

function M.get(key)
  local path = Path:new(vim.fn.stdpath("state") .. "/multiplexer.json")

  if not path:exists() then
    path:touch()
    path:write(vim.json.encode({}), 'w')
    return {}
  end

  local data = path:read()

  local state = vim.json.decode(data)

  if key then
    return state[key]
  end

  return state
end

function M.set(data)
  local path = Path:new(vim.fn.stdpath("state") .. "/multiplexer.json")

  if not path:exists() then
    path:touch()
    path:write(vim.json.encode({}), 'w')
    return
  end

  local updated_state = vim.tbl_extend("force", M.get(), data)

  path:write(vim.json.encode(updated_state), 'w')
end

function M.clear()
  local path = Path:new(vim.fn.stdpath("state") .. "/multiplexer.json")

  if not path:exists() then
    path:touch()
  end

  path:write(vim.json.encode({}), 'w')
end

return M
