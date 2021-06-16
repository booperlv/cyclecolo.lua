# cyclecolo.nvim, A floating colorscheme selector for neovim written in lua



##Notice
This plugin requires [neovim nightly (>=0.5.0)](https://github.com/neovim/neovim/wiki/Installing-Neovim).

##Install

Install with [vim-plug](https://github.com/junegunn/vim-plug):
```vim
Plug 'booperlv/cyclecolo.lua'
```

##Setup

```vim
let g:cyclecolo_close_on_confirm = v:true " Whether or not to close the window on confirm
let g:cyclecolo_preview_colors = v:false " Whether or not to set colorscheme to current one under the cursor
leg g:cyclecolo_preview_text = 'function test() {}' " String to set in the preview window 
let g:cyclecolo_preview_text_syntax = 'javascript' " What syntax will be used in the preview window

lua require('cyclecolo').setup()
nnoremap <C-n> :ColoToggle<CR>
```
