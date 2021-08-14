
# cyclecolo.nvim, A floating colorscheme selector for neovim written in lua

Just a heads up, this will eventually be no longer maintained in favor of
creating something with similar functionality as an extension to a fuzzy finder.
It will likely be for [snap](https://github.com/camspiers/snap) instead of
[telescope](https://github.com/nvim-telescope/telescope.nvim) though, as it is
personally what I use.

https://user-images.githubusercontent.com/65604882/124722836-06804200-df3d-11eb-92cd-cbff1294e3cf.mp4

*Colorschemes: [tokyonight](https://github.com/folke/tokyonight.nvim), [material](https://github.com/marko-cerovac/material.nvim), [ayu](https://github.com/Shatur/neovim-ayu), [miramare](https://github.com/franbach/miramare)    Font: [Iosevka](https://github.com/be5invis/Iosevka)*

## Install

Install with [vim-plug](https://github.com/junegunn/vim-plug):
```vim
Plug 'booperlv/cyclecolo.lua'
```

## Setup

```lua
require('cyclecolo').setup {
  filter_colorschemes = {}, -- Which colorschemes to not show in the selector, 'defaults' or {'table of strings'}
  child_cycles = {  -- Switch between colorscheme "styles", by toggling a variable.
    -- The format is { colorscheme="name", variable="variable-as-string", values={"table", "of", "strings"} }
    { colorscheme="material", variable = "vim.g.material_style", values = { "darker", "lighter", "palenight", "oceanic", "deep ocean" }}
  },
  -- Alternatively, you can use autocmd for ColorScheme, though cyclecolo does not use this.
  attach_events = {'dofile("/home/user/.config/nvim/lua/refreshhiglights.lua")'} -- Lua functions to attach to colorscheme confirm as string
  hover_colors = false, -- Whether or not to set colorscheme to current one under the cursor
  close_on_confirm = false, -- Whether or not to close the selector on confirm, true/false

  mappings = { -- Set the mappings in the select window
    close = "<ESC>", -- Close the window
    confirm = "<CR>", -- Confirm/Apply the colorscheme
    next_child_cycle = "n", -- child_cycle forward, has count support 
    prev_child_cycle = "p" -- child_cycle backward, has count support 
  }

  preview_text = 'lorem ipsum', -- String to set in the preview window 
  preview_text_syntax = 'javascript', -- What syntax will be used in the preview window

  window_border = "single" -- Border for both windows, check nvim_open_win for options
  window_border_highlight = "FloatBorder" -- Highlight group to be used for the window border
  window_blend = 5, -- Transparency of window, 0(none)-100(full).
  window_breakpoint = 55, -- Determines the breakpoint where only the select window is shown, any number
  child_cycle_highlight = "Comment", -- Highlight group to be used for the virtual text that indicates the current child cycle value
}
```
```vim
nnoremap <leader>ct :ColoToggle<CR>
" Pressing <CR> in the window will confirm/apply the colorscheme
" Pressing <ESC> in the window will exit the window
" Pressing n (next) or p (previous) in the window will change child_cycles
```

## Commands

```vim
:ColoOpen "Opens the Selector
:ColoClose "Closes the Selector
:ColoToggle "Opens or Closes the Selector
```
