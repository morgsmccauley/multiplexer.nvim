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
                table.insert(sockets, subdir .. '/' .. subname)
              end
            end
          end
        end
      end
    end
  end

  return sockets
end

local function query_instance_metadata(socket_path)
  local ok, channel = pcall(vim.fn.sockconnect, 'pipe', socket_path, { rpc = true })
  if not ok or channel == 0 then
    return nil, nil
  end

  local cwd, meta
  local success = pcall(function()
    cwd = vim.fn.rpcrequest(channel, 'nvim_eval', 'getcwd()')
    meta = vim.fn.rpcrequest(channel, 'nvim_exec_lua', 'return require("multiplexer.metadata").get()', {})
  end)

  pcall(vim.fn.chanclose, channel)

  if success then
    return cwd, meta
  end
  return nil, nil
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

  for _, socket in ipairs(sockets) do
    if socket ~= current_socket then
      local cwd, meta = query_instance_metadata(socket)
      if cwd and meta and result[cwd] ~= nil then
        result[cwd] = meta
      end
    end
  end

  return result
end

return M
