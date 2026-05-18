local M = {}

local _metadata = {}
local REMOTE_TIMEOUT_MS = 100

function M.set(data)
  _metadata = vim.tbl_extend("force", _metadata, data)
end

function M.get()
  return vim.deepcopy(_metadata)
end

function M.clear()
  _metadata = {}
end

local function pid_from_socket(socket_path)
  local pid = socket_path:match('/nvim%.(%d+)%.%d+$')
  return pid and tonumber(pid)
end

local function pid_is_alive(pid)
  if not pid then
    return true
  end

  local code, _, name = vim.uv.kill(pid, 0)
  return code == 0 or name ~= 'ESRCH'
end

local function find_nvim_sockets()
  local sockets = {}

  local servername = vim.v.servername
  if not servername or servername == '' then
    return sockets
  end

  local nvim_dir = vim.fn.fnamemodify(servername, ':h:h')

  if vim.fn.isdirectory(nvim_dir) == 1 then
    local handle = vim.uv.fs_scandir(nvim_dir)
    if handle then
      while true do
        local name, type = vim.uv.fs_scandir_next(handle)
        if not name then break end
        if type == 'directory' then
          local subdir = nvim_dir .. '/' .. name
          local subhandle = vim.uv.fs_scandir(subdir)
          if subhandle then
            while true do
              local subname, subtype = vim.uv.fs_scandir_next(subhandle)
              if not subname then break end
              if subtype == 'socket' or subname:match('^nvim%.[0-9]+%.[0-9]+$') then
                local socket = subdir .. '/' .. subname
                if pid_is_alive(pid_from_socket(socket)) then
                  table.insert(sockets, socket)
                end
              end
            end
          end
        end
      end
    end
  end

  return sockets
end

local function metadata_command(socket_path)
  local expr = [[luaeval('vim.json.encode({ cwd = vim.fn.getcwd(), meta = require("multiplexer.metadata").get() })')]]

  return {
    'nvim',
    '--server',
    socket_path,
    '--remote-expr',
    expr,
  }
end

local function decode_metadata_result(result)
  if not result or result.code ~= 0 or not result.stdout or result.stdout == '' then
    return nil, nil
  end

  local decoded_ok, decoded = pcall(vim.json.decode, result.stdout)
  if not decoded_ok or type(decoded) ~= 'table' then
    return nil, nil
  end

  return decoded.cwd, decoded.meta
end

local function query_instances_metadata(sockets)
  local jobs = {}

  for _, socket in ipairs(sockets) do
    local ok, job = pcall(vim.system, metadata_command(socket), { text = true, timeout = REMOTE_TIMEOUT_MS })
    if ok then
      table.insert(jobs, job)
    end
  end

  local metadata_by_cwd = {}
  for _, job in ipairs(jobs) do
    local ok, result = pcall(function()
      return job:wait()
    end)

    if ok then
      local cwd, meta = decode_metadata_result(result)
      if cwd and meta then
        metadata_by_cwd[cwd] = meta
      end
    end
  end

  return metadata_by_cwd
end

function M.get_all(project_paths)
  local result = {}
  for _, path in ipairs(project_paths) do
    result[path] = {}
  end

  local current_cwd = vim.fn.getcwd()
  result[current_cwd] = M.get()

  local sockets = find_nvim_sockets()
  local current_socket = vim.v.servername

  local sockets_to_query = {}
  for _, socket in ipairs(sockets) do
    if socket ~= current_socket then
      table.insert(sockets_to_query, socket)
    end
  end

  for cwd, meta in pairs(query_instances_metadata(sockets_to_query)) do
    if result[cwd] ~= nil then
      result[cwd] = meta
    end
  end

  return result
end

return M
