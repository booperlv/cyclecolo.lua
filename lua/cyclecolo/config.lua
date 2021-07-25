local config = {}

local util = require'cyclecolo.utils'

config.plugOpts = nil

function config.mergeDefaults(opts)
  local function previewStringToTable(string)
    local result = {};
    for match in (string..'\n'):gmatch("(.-)"..'\n') do
      table.insert(result, match);
    end
    return result;
  end
  local defaultText = [[
  local function themePreview()
    local reasonsToExist = {
      'cool',
      'I honestly can\'t think of anything else'
    }
    local indexTables = {}
    for index, reason in pairs(reasonsToExist) do
      table.insert(indexTables, {index, reason})
    end
    return indexTables
  end
  themePreview()]]

  local default_opts = {
    filter_colorschemes = {},
    child_cycles = {
      --Format for these children are {colorscheme = 'name', variable = 'name', values = {}}
    },
    attach_events = {},
    hover_colors = false,
    close_on_confirm = false,

    mappings = {
      close = "<ESC>",
      confirm = "<CR>",
      next_child_cycle = "n",
      prev_child_cycle = "p"
    },

    preview_text = defaultText,
    preview_text_syntax = 'lua',

    window_border = 'single',
    window_blend = 5,
    window_breakpoint = 55,
    window_border_highlight = 'FloatBorder',
    child_cycles_highlight = "Comment",
  }
  local mergedTable = util.tableMerge(default_opts, opts)
  mergedTable.preview_text = previewStringToTable(mergedTable.preview_text)
  config.plugOpts = mergedTable
  return mergedTable
end

return config
