local M = {}

local cache = {
  paths = nil,
  timestamp = 0,
  ttl = 30000
}

function M.get_project_paths()
  local now = vim.uv.now()

  if cache.paths and (now - cache.timestamp) < cache.ttl then
    return cache.paths
  end

  local config = require('multiplexer.config')
  local utils = require('multiplexer.utils')

  cache.paths = utils.list_all_sub_directories(config.options.project_paths)
  cache.timestamp = now

  return cache.paths
end

function M.invalidate()
  cache.paths = nil
  cache.timestamp = 0
end

function M.set_ttl(ttl_ms)
  cache.ttl = ttl_ms
end

return M
