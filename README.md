# multiplexer.nvim

Code project management tool for Neovim with Kitty and WezTerm support.

## Philosophy

Frequently, I find myself working across multiple code repositories, switching back and forth between them. Vim sessions can work well for this, but major drawback is they only persist buffers and window layout, sacraficing key elements like embedded terminals and plugin state.

While Tmux is a common progression, it adds the overhead of learning a new tool: understanding how to manipulate windows, panes, tabs, and figuring out keybindings within terminals, all of which are possible within Neovim alone.

Many modern terminals, including Kitty and WezTerm, come with most of the functionality Tmux provides. Therefore, to avoid introducing an unnecessary layer and to maximize the use of Neovim's functionality, I developed this plugin. Its purpose is to leverage the multiplexing capabilities provided by your terminal, enabling comprehensive project management from within Neovim.

## Features

- Seamlessly manage multiple persistant Neovim instances
- Automatic loading of, and continouously updated, sessions
- Telescope and Snacks picker integration
- Support for Kitty and WezTerm terminals

## How it works

multiplexer.nvim uses the remote control capabilities of Kitty or WezTerm to manage multiple instances of Neovim, exposing a simplified API for managing these instances. Each terminal window/pane maps to a single Neovim instance.

### Kitty
Uses [remote control](https://sw.kovidgoyal.net/kitty/overview/#remote-control) to manage Kitty windows. Works best with the [stack layout](https://sw.kovidgoyal.net/kitty/overview/#layouts).

### WezTerm
Uses the [WezTerm CLI](https://wezfurlong.org/wezterm/cli/general.html) to manage panes.

## Installation

### Using lazy.nvim

```lua
return {
  'morgsmccauley/multiplexer.nvim',
  config = function()
    require('multiplexer').setup()
  end
}
```

## Configuration

```lua
{
  terminal = 'auto', -- 'auto', 'kitty', or 'wezterm'
  command = 'zsh --login -c nvim', -- command used to start the Neovim instance
  picker = 'telescope', -- picker to use: 'telescope' or 'snacks'
  project_paths = { -- list of project paths
    { vim.env.HOME .. '/Developer', exclude_hidden = true }, -- all subdirectories will be included from nested tables
    { vim.env.HOME .. '/.local/share/nvim/lazy', exclude_hidden = false },
    vim.env.HOME .. '/.dotfiles' -- list a single directory to be included
  }
}
```

The `terminal` option defaults to `'auto'`, which detects the terminal automatically:
1. Checks `KITTY_PID` env var → Kitty
2. Checks `WEZTERM_PANE` env var → WezTerm

By default, terminals use a non-login shell to run the command provided. If your setup relies on login initialization files being sourced, you can use `zsh --login -c nvim` to start Neovim within a login shell.

## Usage

Management is centered around pickers (Telescope or Snacks). To list all projects:

### Using Telescope (default)
```
Telescope multiplexer projects
```

### Using the command
```
:MuxProjects
```

### Using Snacks
```lua
require('multiplexer').projects()
```

Or configure the picker and use:
```lua
require('multiplexer').setup({ picker = 'snacks' })
require('multiplexer').projects()
```

Active projects will be listed first, these are annotated similar to buffer (`:h ls`) indicators:
- `%a` - current project
- `#a` - previous project
- `a` - active project

The previous project is always listed first to allow quick switching to it.

Within both pickers, projects can be managed via the following keybindings:
- `<Cr>` - Switch to project, launching it if required
- `<C-x>` - Close project
- `<C-r>` - Restart project, closing and relaunching

## Commands

- `:MuxProjects` - Open the projects picker
- `:MuxProjectsRefresh` - Refresh the project cache
- `:MuxProjectsCurrent` - Show current project info

## Health Check

Run `:checkhealth multiplexer` to verify your setup.
