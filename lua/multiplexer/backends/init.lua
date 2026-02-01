local M = {}

local loaded_backend = nil

local function detect_terminal()
  if vim.env.KITTY_PID then
    return 'kitty'
  elseif vim.env.WEZTERM_PANE then
    return 'wezterm'
  end
  return nil
end

function M.get()
  if loaded_backend then
    return loaded_backend
  end

  local config = require('multiplexer.config')
  local terminal = config.options.terminal

  if terminal == 'auto' then
    terminal = detect_terminal()
    if not terminal then
      vim.notify('multiplexer: Could not detect terminal. Set terminal option explicitly.', vim.log.levels.ERROR)
      return nil
    end
  end

  local ok, backend = pcall(require, 'multiplexer.backends.' .. terminal)
  if not ok then
    vim.notify('multiplexer: Failed to load backend: ' .. terminal, vim.log.levels.ERROR)
    return nil
  end

  if not backend.is_available() then
    vim.notify('multiplexer: Backend ' .. terminal .. ' is not available', vim.log.levels.ERROR)
    return nil
  end

  loaded_backend = backend
  return loaded_backend
end

function M.get_detected_terminal()
  return detect_terminal()
end

function M.reset()
  loaded_backend = nil
end

return M
