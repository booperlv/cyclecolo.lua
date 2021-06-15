if !has('nvim-0.5') || exists('g:loaded_cyclecolo') | finish | endif

command! ColoOpen lua require('cyclecolo').open()
command! ColoClose lua require('cyclecolo').close()
command! ColoToggle lua require('cyclecolo').toggle()
command! ColoConfirm lua require('cyclecolo').confirm()

nnoremap <leader>ct :ColoToggle<CR>
nnoremap <leader>cc :ColoConfirm<CR>

let g:loaded_cyclecolo = 1
