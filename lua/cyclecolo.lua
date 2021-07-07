local M = {}
local api = vim.api

-----------------

local arrayOfColorschemes = vim.fn.getcompletion('', 'color')
local previewbuf
local previewwin
local buf
local win



-----------------
--Option Defaults
-----------------



local function tableMerge(t1, t2)
    for k,v in pairs(t2) do
        if type(v) == "table" then
            if type(t1[k] or false) == "table" then
                tableMerge(t1[k] or {}, t2[k] or {})
            else
                t1[k] = v
            end
        else
            t1[k] = v
        end
    end
    return t1
end

local function mergeDefaultOpts(opts)
    local function previewStringToTable(string)
        local result = {};
        for match in (string..'\n'):gmatch("(.-)"..'\n') do
            table.insert(result, match);
        end
        return result;
    end
    local defaultText = [[local function themePreview()
    local reasonsToExist = {
        'cool',
        'I honestly can\'t think of anything else'
    }
    local indexTables = {}
    for index, reason in reasonsToExist do
        table.insert(indexTables, {index, reason})
    end
    return indexTables
end
themePreview()]]

    local default_opts = {
        window_blend = 5,
        window_breakpoint = 55,

        close_on_confirm = false,
        hover_colors = false,

        filter_colorschemes = {},

        preview_text = defaultText,
        preview_text_syntax = 'lua',

        attach_events = {},
        child_cycles = {
            --Format for these children are {colorscheme = 'name', variable = 'name', values = {}}
        },
        child_cycles_highlight = "Comment",

        mappings = {
            close = "<ESC>",
            confirm = "<CR>",
            next_child_cycle = "n",
            prev_child_cycle = "p"
        }
    }
    local newTable = tableMerge(default_opts, opts)
    newTable.preview_text = previewStringToTable(newTable.preview_text)
    return newTable
end

local plugOpts
function M.setup(opts)
    vim.cmd([[
        command! ColoOpen lua require('cyclecolo').open()
        command! ColoClose lua require('cyclecolo').close()
        command! ColoToggle lua require('cyclecolo').toggle()
        nmap <silent> <Plug>ColoConfirm :lua require('cyclecolo').confirm()<CR>
        nmap <silent> <Plug>ColoNextCCycle :lua require('cyclecolo').incrementChildCycles( vim.v.count1)<CR>
        nmap <silent> <Plug>ColoPrevCCycle :lua require('cyclecolo').incrementChildCycles(-vim.v.count1)<CR>
    ]])
    plugOpts = mergeDefaultOpts(opts)
end



-----------------
--Window Creation
-----------------



local createdSelect = false
local function createSelectWindow(opts)
    buf = api.nvim_create_buf(false, true)
    win = api.nvim_open_win(buf, true, opts)

    api.nvim_win_set_option(win, 'winhl', 'Normal:Normal')
    api.nvim_win_set_option(win, 'winblend', plugOpts.window_blend)

    --Add sorting and stuff here
    --Hide/remove colorschemes that are inside the filter_colorschemes table
    local function filterColorschemes()
        local returnValue = arrayOfColorschemes
        if plugOpts.filter_colorschemes ~= 'defaults' then
            for _, filter in pairs(plugOpts.filter_colorschemes) do
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
    api.nvim_buf_set_lines(buf, 0, 1, true, filterColorschemes())
    createdSelect = true
end

local createdPreview = false
local function createPreviewWindow(opts)
    previewbuf = api.nvim_create_buf(false, true)
    previewwin = api.nvim_open_win(previewbuf, false, opts)

    api.nvim_win_call(previewwin, loadstring('vim.opt.syntax = "'.. plugOpts.preview_text_syntax ..'"'))
    api.nvim_win_set_option(previewwin, 'winhl', 'Normal:Normal')
    api.nvim_win_set_option(win, 'winblend', plugOpts.window_blend)
    api.nvim_buf_set_lines(previewbuf, 0, 1, true, plugOpts.preview_text)
    createdPreview = true
end



------------------
--Feature Handling
------------------



local function getContentOfCurrentRow()
    local cursor = api.nvim_win_get_cursor(win)
    local row = cursor[1]
    local rowContent = api.nvim_buf_get_lines(buf, row-1, row, true)
    return rowContent[1]
end

local colorschemeBeforeCycle
function M.setPreviewHighlights()
    --Maybe oneday when it is possible, set colorscheme only for preview window
    if api.nvim_win_get_buf(0) == buf and plugOpts.hover_colors == true then
        if colorschemeBeforeCycle == nil then
            colorschemeBeforeCycle = vim.g.colors_name
        end
        local currentHovered = getContentOfCurrentRow()
        if currentHovered ~= '' then
            api.nvim_command('colorscheme ' .. currentHovered)
        end
    end
end

local function get_index (tab, val)
    for i, v in ipairs(tab) do
        if v == val then
            return i
        end
    end
end

-----------------------------

local childCycleNameSpace = api.nvim_create_namespace("childcycle")
local function setVirtualTextWithValueToRow(value, colorscheme)
    local indexOfColorscheme = get_index(api.nvim_buf_get_lines(buf, 1, -1, true), colorscheme)
    api.nvim_buf_clear_namespace(buf, childCycleNameSpace, indexOfColorscheme, indexOfColorscheme+1)
    api.nvim_buf_set_extmark(buf, childCycleNameSpace, indexOfColorscheme, indexOfColorscheme+1, {
        virt_text = {{value, "Comment"}},
    })
end

function M.incrementChildCycles(count)
    local function toggleBetweenOpts(colorscheme, variable, values)
        --Use these weird loadstring functions as we are passing the variable down as a string.
        --God this took so long to figure out LOL. Only way to access/reference the variable
        --in this scope is through a loadstring.
        local variableValue = loadstring("return "..variable)()
        local indexOfValue = get_index(values, variableValue)
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
        setVirtualTextWithValueToRow(nextValue, colorscheme)
    end

    local currentHovered = getContentOfCurrentRow()
    for _, childObject in pairs(plugOpts.child_cycles) do
        if childObject.colorscheme == currentHovered then
            toggleBetweenOpts(childObject.colorscheme, childObject.variable, childObject.values)
            M.confirm()
        end
    end
end



-----------------------
--Interfacing functions
-----------------------



local isCycleOpen = false

function M.toggle()
    if isCycleOpen == true then
        M.close()
    else
        M.open()
    end
end

function M.open()
    --If columns is less than window breakpoint, only open the select window
    --and don't open the preview. Otherwise, open both.
    if (vim.o.columns < plugOpts.window_breakpoint) then
        local width = math.floor( vim.o.columns * 0.9 )
        local height = math.floor( vim.o.lines * 0.8 )

        local position = {
            row = math.floor(((vim.o.lines - height)/2) - 1),
            col = math.floor(((vim.o.columns - width)/2) - 1),
        }

        createSelectWindow({
            relative="editor",
            row=position['row'],
            col=position['col'],
            width=width,
            height=height,
            border='single',
            style='minimal',
        })
    else
        local padding = math.floor( vim.o.columns * 0.05 )
        local width = math.floor( vim.o.columns * 0.425 )
        local height = math.floor( vim.o.lines * 0.8 )

        local position = {
            row = math.floor(((vim.o.lines - height)/2) - 1),
            col = 1 + padding
        }
        local previewposition = {
            row = math.floor(((vim.o.lines - height)/2) - 1),
            col = math.floor( (position.col + width + padding) )
        }

        createSelectWindow({
            relative="editor",
            row=position['row'],
            col=position['col'],
            width=width,
            height=height,
            border='single',
            style='minimal',
        })

        createPreviewWindow({
            relative="editor",
            row=previewposition['row'],
            col=previewposition['col'],
            width=width,
            height=height,
            border='single',
            focusable=false,
        })
    end

    vim.opt.modifiable = false

    local function setCursorToCurrentColorscheme()
        local currentColorscheme = vim.g.colors_name
        local indexOfCurrentColorscheme
        for index,colo in pairs(arrayOfColorschemes) do
            if colo == currentColorscheme then
                indexOfCurrentColorscheme = index
                break
            end
        end
        api.nvim_win_set_cursor(win, {indexOfCurrentColorscheme, 0})
    end
    setCursorToCurrentColorscheme()

    for _, childObject in pairs(plugOpts.child_cycles) do
        local variable = loadstring("return "..childObject.variable)()
        if variable == nil and next(childObject.values) ~= nil then
            variable = childObject.values[1]
            loadstring(childObject.variable.."="..'"'..childObject.values[1]..'"')()
        end
        setVirtualTextWithValueToRow(variable, childObject.colorscheme)
    end

    if plugOpts.hover_colors == true then
        api.nvim_command([[augroup cyclecolo_autocommands]])
        api.nvim_command([[autocmd CursorMoved * lua require('cyclecolo').setPreviewHighlights()]])
        api.nvim_command([[augroup END]])
    end

    vim.cmd([[
        augroup cyclecolo_buf_exit
        autocmd BufLeave * ColoClose
        augroup END
    ]])

    --Map these to the select window, so that when it is deleted the mapping delete as well
    api.nvim_buf_set_keymap(buf, 'n', plugOpts.mappings.close, ":ColoClose<CR>", {})
    api.nvim_buf_set_keymap(buf, 'n', plugOpts.mappings.confirm, "<Plug>ColoConfirm", {})
    --Add option to map this
    api.nvim_buf_set_keymap(buf, 'n', plugOpts.mappings.next_child_cycle, "<Plug>ColoNextCCycle", {})
    api.nvim_buf_set_keymap(buf, 'n', plugOpts.mappings.prev_child_cycle, "<Plug>ColoPrevCCycle", {})

    isCycleOpen = true
end

function M.close()
    if createdSelect then
        api.nvim_buf_delete(buf, {})
        createdSelect = false
    end
    if createdPreview then
        api.nvim_buf_delete(previewbuf, {})
        createdPreview = false
    end

    vim.opt.modifiable = true

    if colorschemeBeforeCycle ~= nil then
        api.nvim_command('colorscheme '..colorschemeBeforeCycle)
    end

    if plugOpts.hover_colors == true then
        api.nvim_command([[augroup cyclecolo_autocommands]])
        api.nvim_command([[autocmd!]])
        api.nvim_command([[augroup END]])
    end

    vim.cmd([[
        augroup cyclecolo_buf_exit
        autocmd!
        augroup END
    ]])
    isCycleOpen = false

end


function M.confirm()
    local currentbackground = vim.opt.background

    local function setColoBasedOnLineContent()
        local currentHovered = getContentOfCurrentRow()
        if currentHovered ~= '' then
            vim.cmd('colorscheme '..currentHovered)
        end
    end
    setColoBasedOnLineContent()

    vim.opt.background = currentbackground

    colorschemeBeforeCycle = nil

    if plugOpts.close_on_confirm == true then
        M.close()
    end
    for _, value in pairs(plugOpts.attach_events) do
        api.nvim_command('lua '..value)
    end
end

return M
