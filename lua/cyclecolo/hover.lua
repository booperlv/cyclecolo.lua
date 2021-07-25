local hover = {}

function hover.setPreviewHighlights()
  --Maybe oneday when it is possible, set colorscheme only for preview window
  local win = require'cyclecolo.window'
  local conf = require'cyclecolo.config'
  if vim.api.nvim_win_get_buf(0) == win.selectbuf and conf.plugOpts.hover_colors == true then
    conf.plugOpts.close_on_confirm = false
    require'cyclecolo'.confirm()
  end
end

return hover
