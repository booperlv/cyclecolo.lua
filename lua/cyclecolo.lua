local cyclecolo = {}

function cyclecolo.setup(opts)
  vim.cmd([[
    command! ColoOpen lua require('cyclecolo').open()
    command! ColoClose lua require('cyclecolo').close()
    command! ColoToggle lua require('cyclecolo').toggle()
    nmap <silent> <Plug>ColoConfirm :lua require('cyclecolo').confirm()<CR>
    nmap <silent> <Plug>ColoNextCCycle :lua require('cyclecolo.childcycle').incrementChildCycles( vim.v.count1)<CR>
    nmap <silent> <Plug>ColoPrevCCycle :lua require('cyclecolo.childcycle').incrementChildCycles(-vim.v.count1)<CR>
  ]])
  local conf = require'cyclecolo.config'
  conf.mergeDefaults(opts)
end


local isCycleOpen = false

function cyclecolo.toggle()
  if isCycleOpen == true then
    cyclecolo.close()
  else
    cyclecolo.open()
  end
end

function cyclecolo.open()
  local conf = require'cyclecolo.config'
  --If columns is less than window breakpoint, only open the select window
  --and don't open the preview. Otherwise, open both.
  local win = require'cyclecolo.window'
  if (vim.o.columns < conf.plugOpts.window_breakpoint) then
    win.selectOnly()
  else
    win.selectAndPreview()
  end

  vim.opt.modifiable = false

  require'cyclecolo.childcycle'.setInitialVirtualText(win.selectbuf)

  if conf.plugOpts.hover_colors == true then
    vim.api.nvim_command([[augroup cyclecolo_autocommands]])
    vim.api.nvim_command([[autocmd CursorMoved * lua require('cyclecolo.hover').setPreviewHighlights()]])
    vim.api.nvim_command([[augroup END]])
  end

  vim.cmd([[
  augroup cyclecolo_buf_exit
  autocmd BufLeave * ColoClose
  augroup END
  ]])

  --Map these to the select window, so that when it is deleted the mapping delete as well
  vim.api.nvim_buf_set_keymap(win.selectbuf, 'n', conf.plugOpts.mappings.close, ":ColoClose<CR>", {})
  vim.api.nvim_buf_set_keymap(win.selectbuf, 'n', conf.plugOpts.mappings.confirm, "<Plug>ColoConfirm", {})
  --Add option to map this
  vim.api.nvim_buf_set_keymap(win.selectbuf, 'n', conf.plugOpts.mappings.next_child_cycle, "<Plug>ColoNextCCycle", {})
  vim.api.nvim_buf_set_keymap(win.selectbuf, 'n', conf.plugOpts.mappings.prev_child_cycle, "<Plug>ColoPrevCCycle", {})

  local function setCursorToCurrentColorscheme()
    local currentColorscheme = vim.g.colors_name
    local lines = vim.fn.getline(1, '$')
    local indexOfName
    for index, value in pairs(lines) do
      if currentColorscheme == value then
        indexOfName = index
      end
    end

    if indexOfName ~= nil then
      vim.api.nvim_win_set_cursor(win, {indexOfName, 0})
    end
  end
  setCursorToCurrentColorscheme()

  isCycleOpen = true
end

function cyclecolo.close()
  local win = require'cyclecolo.window'
  if win.createdSelect then
    vim.api.nvim_buf_delete(win.selectbuf, {})
    win.createdSelect = false
  end
  if win.createdPreview then
    vim.api.nvim_buf_delete(win.previewbuf, {})
    win.createdPreview = false
  end

  vim.opt.modifiable = true

  local conf = require'cyclecolo.config'
  if conf.plugOpts.hover_colors == true then
    vim.api.nvim_command([[augroup cyclecolo_autocommands]])
    vim.api.nvim_command([[autocmd!]])
    vim.api.nvim_command([[augroup END]])
  end

  vim.cmd([[
  augroup cyclecolo_buf_exit
  autocmd!
  augroup END
  ]])
  isCycleOpen = false
end

function cyclecolo.confirm()
  local util = require'cyclecolo.utils'
  local function setColoBasedOnLineContent()
    local currentHovered = util.getContentOfCurrentRow(require'cyclecolo.window'.selectwin,require'cyclecolo.window'.selectbuf)
    if currentHovered ~= '' then
      vim.o.background = util.defaultBackground
      vim.cmd('colorscheme '..currentHovered)
    end
  end
  setColoBasedOnLineContent()

  local conf = require'cyclecolo.config'
  if conf.plugOpts.close_on_confirm == true then
    cyclecolo.close()
  end
  for _, value in pairs(conf.plugOpts.attach_events) do
    vim.api.nvim_command('lua '..value)
  end
end

return cyclecolo
