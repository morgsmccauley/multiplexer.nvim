local Config = require('multiplexer.config')

local M = {}

M.session_loaded = false;

function M.get_current()
  local name = vim.fn.getcwd():gsub('/', '__')
  return Config.options.session_dir .. name .. '.vim'
end

function M.setup()
  vim.fn.mkdir(Config.options.session_dir, 'p')
  M.start()
end

function M.start()
  local group = vim.api.nvim_create_augroup('multiplexer', { clear = true })

  vim.api.nvim_create_autocmd('VimLeavePre', {
    group = group,
    callback = M.save,
  })

  vim.api.nvim_create_autocmd({ 'VimEnter' }, {
    group = group,
    callback = function()
      vim.schedule(M.load)
    end,
  })

  vim.api.nvim_create_autocmd({ 'BufEnter' }, {
    group = group,
    callback = function()
      if not M.session_loaded then
        return
      end

      M.save()
    end,
  })
end

function M.save()
  local session_file = M.get_current()
  local tmp = vim.o.sessionoptions

  pcall(function()
    vim.o.sessionoptions = table.concat(Config.options.session_opts, ',')
    vim.cmd('mksession! ' .. vim.fn.fnameescape(session_file))
  end)

  vim.o.sessionoptions = tmp
end

function M.load()
  local sfile = M.get_current()
  if sfile and vim.fn.filereadable(sfile) ~= 0 then
    local ok, err = pcall(function()
      vim.cmd('silent! source ' .. vim.fn.fnameescape(sfile))
    end)

    if ok then
      M.session_loaded = true
    else
      vim.notify('multiplexer: Failed to load session: ' .. err, vim.log.levels.WARN)
    end
  end
end

return M
