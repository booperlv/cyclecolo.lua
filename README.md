# cyclecolo.nvim, A floating colorscheme selector for neovim written in lua

![cyclecolo demo](https://user-images.githubusercontent.com/65604882/122340239-9f422400-cf74-11eb-83d1-a2c97b9d23c5.gif)
*Colorschemes: [miramare](https://github.com/franbach/miramare), [ayu](https://github.com/Shatur/neovim-ayu), [tokyonight](https://github.com/folke/tokyonight.nvim)  Font: [Iosevka](https://github.com/be5invis/Iosevka)*

## Install

Install with [vim-plug](https://github.com/junegunn/vim-plug):
```vim
Plug 'booperlv/cyclecolo.lua'
```

## Setup

```vim
" These are the default options
```lua
lua require('cyclecolo').setup {
  window_blend = 5, -- Transparency of window, 0(none)-100(full).
  window_breakpoint = 55, -- Determines the breakpoint where only the select window is shown, any number
  filter_colorschemes = {}, -- Which colorschemes to not show in the selector, 'defaults' or {'table of strings'}
  close_on_confirm = false, -- Whether or not to close the selector on confirm, true/false
  hover_colors = false, -- Whether or not to set colorscheme to current one under the cursor
  preview_text = 'lorem ipsum', -- String to set in the preview window 
  preview_text_syntax = 'javascript', -- What syntax will be used in the preview window
  --Alternatively, you can use autocmd for ColorScheme, though cyclecolo does not use this.
  attach_events = {'dofile("/home/user/.config/nvim/lua/refreshhiglights.lua")'} --Lua functions to attach to colorscheme confirm
}
```
nnoremap <leader>ct :ColoToggle<CR>
" Pressing <CR> in the window will confirm/apply the colorscheme
" Pressing <ESC> in the window will exit the window
```
## Commands

```vim
:ColoOpen "Opens the Selector
:ColoClose "Closes the Selector
:ColoToggle "Opens or Closes the Selector
```
