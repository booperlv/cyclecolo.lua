local window = {}

local util = require'cyclecolo.utils'

window.selectbuf = nil
window.selectwin = nil
window.previewbuf = nil
window.previewwin = nil



window.createdSelect = false

function window.createSelectWindow(opts)
  local conf = require'cyclecolo.config'
  local default_opts = {
    relative="editor",
    border=conf.plugOpts.window_border,
    style="minimal",
  }
  local appliedDefaults = util.tableMerge(default_opts, opts)

  window.selectbuf = vim.api.nvim_create_buf(false, true)
  window.selectwin = vim.api.nvim_open_win(window.selectbuf, true, appliedDefaults)

  vim.api.nvim_win_set_option(window.selectwin, 'winhl', 'FloatBorder:'..conf.plugOpts.window_border_highlight)
  vim.api.nvim_win_set_option(window.selectwin, 'winhl', 'Normal:Normal')
  vim.api.nvim_win_set_option(window.selectwin, 'winblend', conf.plugOpts.window_blend)

  --Hide/remove colorschemes that are inside the filter_colorschemes table
  local function filterColorschemes()
    local returnValue = util.arrayOfColorschemes
    if conf.plugOpts.filter_colorschemes ~= 'defaults' then
      for _, filter in pairs(conf.plugOpts.filter_colorschemes) do
        for index, colorscheme in pairs(returnValue) do
          if colorscheme == filter then
            table.remove(returnValue, index)
          end
        end
      end
    else
      local default_colorschemes = {'default', 'blue', 'darkblue', 'delek', 'desert', 'elflord', 'evening', 'industry', 'koehler', 'morning', 'murphy', 'pablo', 'peachpuff', 'ron', 'shine', 'slate', 'torte', 'zellner'}
      for _, filter in pairs(default_colorschemes) do
        for index, colorscheme in pairs(returnValue) do
          if colorscheme == filter then
            table.remove(returnValue, index)
          end
        end
      end
    end
    return returnValue
  end
  vim.api.nvim_buf_set_lines(window.selectbuf, 0, 1, true, filterColorschemes())
  window.createdSelect = true
end



window.createdPreview = false

function window.createPreviewWindow(opts)
  local conf = require'cyclecolo.config'
  local default_opts = {
    relative="editor",
    border=conf.plugOpts.window_border,
    focusable=false,
  }
  local appliedDefaults = util.tableMerge(default_opts, opts)

  window.previewbuf = vim.api.nvim_create_buf(false, true)
  window.previewwin = vim.api.nvim_open_win(window.previewbuf, false, appliedDefaults)

  vim.api.nvim_win_call(window.previewwin, loadstring('vim.opt.syntax = "'.. conf.plugOpts.preview_text_syntax ..'"'))
  vim.api.nvim_win_set_option(window.previewwin, 'winhl', 'FloatBorder:'..conf.plugOpts.window_border_highlight)
  vim.api.nvim_win_set_option(window.previewwin, 'winhl', 'Normal:Normal')
  vim.api.nvim_win_set_option(window.previewwin, 'winblend', conf.plugOpts.window_blend)

  vim.api.nvim_buf_set_lines(window.previewbuf, 0, 1, true, conf.plugOpts.preview_text)
  window.createdPreview = true
end




function window.selectOnly()
  local width = math.floor( vim.o.columns * 0.9 )
  local height = math.floor( vim.o.lines * 0.8 )

  local position = {
    row = math.floor( ((vim.o.lines - height )/2) - 1 ),
    col = math.floor( ((vim.o.columns - width)/2) - 1 ),
  }

  window.createSelectWindow({
    row=position['row'],
    col=position['col'],
    width=width,
    height=height,
  })
end


function window.selectAndPreview()
  local padding = math.floor( vim.o.columns * 0.025 )
  local width = math.floor( vim.o.columns * 0.45 )
  local height = math.floor( vim.o.lines * 0.8 )

  local position = {
    row = math.floor( ((vim.o.lines - height )/2) - 1 ),
    --Go to center, then minus width/2 to have right side sit on center
    --Then add padding to set the spacing between both halves
    --  ((centercenter)) -> (-width/2|-width/2) -> (center) spacing (center)
    col = math.floor( (((vim.o.columns - width)/2) - 1) - (width/2) - (padding/2) )
  }
  local previewposition = {
    row = math.floor( ((vim.o.lines - height )/2) - 1 ),
    --Go to center, then add width/2 to have left side sit on center
    --Then add padding to set the spacing between both halves
    --  ((centercenter)) -> (-width/2|-width/2) -> (center) spacing (center)
    col = math.floor( (((vim.o.columns - width)/2) - 1) + (width/2) + (padding/2) )
  }

  window.createSelectWindow({
    row=position['row'],
    col=position['col'],
    width=width,
    height=height,
  })

  window.createPreviewWindow({
    row=previewposition['row'],
    col=previewposition['col'],
    width=width,
    height=height,
  })
end

return window
