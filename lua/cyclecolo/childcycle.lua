local childcycle = {}

local util = require'cyclecolo.utils'

function childcycle.setInitialVirtualText(buffer)
  local conf = require'cyclecolo.config'
  for _, childObject in pairs(conf.plugOpts.child_cycles) do
    local variable = loadstring("return "..childObject.variable)()
    if util.exists_in(util.arrayOfColorschemes, childObject.colorscheme) then
      if next(childObject.values) ~= nil then
        if variable == nil or variable == '' then
          variable = childObject.values[1]
          loadstring(childObject.variable.."="..'"'..childObject.values[1]..'"')()
        end
        childcycle.setVirtualTextWithValueToRow(buffer, variable, childObject.colorscheme)
      end
    else
      print("Can't set the child_cycle for \""..childObject.colorscheme.."\"! Could not be found")
    end
  end
end

childcycle.namespace = vim.api.nvim_create_namespace("childcycle")
function childcycle.setVirtualTextWithValueToRow(buffer, value, colorscheme)
  local indexOfColorscheme = util.get_index(vim.api.nvim_buf_get_lines(buffer, 1, -1, true), colorscheme)
  vim.api.nvim_buf_clear_namespace(buffer, childcycle.namespace, indexOfColorscheme, indexOfColorscheme+1)
  vim.api.nvim_buf_set_extmark(buffer, childcycle.namespace, indexOfColorscheme, 1, {
    virt_text = {{value, "Comment"}},
  })
end

function childcycle.incrementChildCycles(count)
  local function toggleBetweenOpts(colorscheme, variable, values)
    --Use these weird loadstring functions as we are passing the variable down as a string.
    --Only way to access/reference the variable in this scope is through a loadstring.
    local variableValue = loadstring("return "..variable)()
    local indexOfValue = util.get_index(values, variableValue)
    local nextValue
    if count > 0 then
      if indexOfValue < #values then
        nextValue = values[indexOfValue+count]
      else
        nextValue = values[1]
      end
    else
      if indexOfValue > 1 then
        nextValue = values[indexOfValue+count]
      else
        nextValue = values[#values]
      end
    end
    loadstring(variable.." = "..'"'..nextValue..'"'.."; return "..variable)()
    childcycle.setVirtualTextWithValueToRow(require'cyclecolo.window'.selectbuf, nextValue, colorscheme)
  end

  local conf = require'cyclecolo.config'
  local currentHovered = util.getContentOfCurrentRow()
  for _, childObject in pairs(conf.plugOpts.child_cycles) do
    if util.exists_in(util.arrayOfColorschemes, childObject.colorscheme) then
      if childObject.colorscheme == currentHovered then
        toggleBetweenOpts(childObject.colorscheme, childObject.variable, childObject.values)
        require'cyclecolo'.confirm()
      end
    end
  end
end


return childcycle
