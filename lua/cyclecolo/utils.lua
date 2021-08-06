local utils = {}

utils.arrayOfColorschemes = vim.fn.getcompletion('', 'color')
utils.defaultBackground = vim.o.background

function utils.tableMerge(t1, t2)
  for k,v in pairs(t2) do
    if type(v) == "table" then
    if type(t1[k] or false) == "table" then
        utils.tableMerge(t1[k] or {}, t2[k] or {})
      else
        t1[k] = v
      end
    else
      t1[k] = v
    end
  end
  return t1
end

function utils.exists_in (tab, val)
  for _, value in ipairs(tab) do
    if value == val then
      return true
    end
  end
  return false
end

function utils.get_index (tab, val)
  for i, v in ipairs(tab) do
    if v == val then
      return i
    end
  end
end

function utils.getContentOfCurrentRow()
    return vim.fn.getline(".")
end

return utils
