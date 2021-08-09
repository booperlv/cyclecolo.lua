local hover = {}

function hover.setPreviewHighlights()
  --Maybe oneday when it is possible, set colorscheme only for preview window
  local conf = require'cyclecolo.config'
  conf.plugOpts.close_on_confirm = false

  local confirmKey = conf.plugOpts.mappings.confirm
  vim.cmd( [[call feedkeys("\]]..confirmKey..'")' )
end

return hover
