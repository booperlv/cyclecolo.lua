# cyclecolo.nvim, A floating colorscheme selector for neovim written in lua

![cyclecolo demo](https://user-images.githubusercontent.com/65604882/122340239-9f422400-cf74-11eb-83d1-a2c97b9d23c5.gif)
*Colorschemes: [miramare](https://github.com/franbach/miramare), [ayu](https://github.com/Shatur/neovim-ayu), [tokyonight](https://github.com/folke/tokyonight.nvim)  Font: [Iosevka](https://github.com/be5invis/Iosevka)*

## Notice
This plugin requires [neovim nightly (>=0.5.0)](https://github.com/neovim/neovim/wiki/Installing-Neovim).

## Install

Install with [vim-plug](https://github.com/junegunn/vim-plug):
```vim
Plug 'booperlv/cyclecolo.lua'
```

## Setup

```vim
let g:cyclecolo_window_blend = 5 " Transparency of window, 0 for no transparency, 100 for full transparency
let g:cyclecolo_close_on_confirm = v:false " Whether or not to close the window on confirm
let g:cyclecolo_preview_colors = v:false " Whether or not to set colorscheme to current one under the cursor
let g:cyclecolo_preview_text = 'function test() {}' " String to set in the preview window 
let g:cyclecolo_preview_text_syntax = 'javascript' " What syntax will be used in the preview window
let g:cyclecolo_attach_events = [ 'dofile("/home/user/.config/nvim/lua/refreshhiglights.lua")' ]  " Lua functions to attach to colorscheme change/confirm

lua require('cyclecolo').setup()
nnoremap <leader>ct :ColoToggle<CR>
" Pressing <CR> in the window will confirm/apply the colorscheme :)
```
## Commands

```vim
:ColoOpen "Opens the Selector
:ColoClose "Closes the Selector
:ColoToggle "Opens or Closes the Selector
```
