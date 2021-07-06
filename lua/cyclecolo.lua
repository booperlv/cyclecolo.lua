local M = {}
local api = vim.api

------------------------
--Lines to take note of
----85 -- Add filter option for all default vim colorschemes
----85 -- Sorting, Grouping via folds, Hide colorschemes
----249 -- Create "sub-colorschemes" - virtual text variable toggling

-------------------------

local arrayOfColorschemes = vim.fn.getcompletion('', 'color')
local previewbuf
local previewwin
local buf
local win

-----------------
--Option Defaults
-----------------

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

    return {
        window_blend = opts["window_blend"] or 5,
        window_breakpoint = opts["window_breakpoint"] or 55,

        close_on_confirm = opts["close_on_confirm"] or false,
        hover_colors = opts["hover_colors"] or false,

        filter_colorschemes = opts["filter_colorschemes"] or {},

        preview_text = previewStringToTable(opts["preview_text"] or defaultText),
        preview_text_syntax = opts["preview_text_syntax"] or 'lua',

        attach_events = opts["attach_events"] or {},
        child_cycles = opts["color_attach"] or {}
    }
end

local plugOpts
function M.setup(opts)
    vim.cmd([[
        command! ColoOpen lua require('cyclecolo').open()
        command! ColoClose lua require('cyclecolo').close()
        command! ColoToggle lua require('cyclecolo').toggle()
        command! ColoConfirm lua require('cyclecolo').confirm()
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

----------------
--Preview Colors
----------------

local colorschemeBeforeCycle
function M.setPreviewHighlights()
    if api.nvim_win_get_buf(0) == buf and plugOpts.hover_colors == true then
        if colorschemeBeforeCycle == nil then
            colorschemeBeforeCycle = vim.g.colors_name
        end

        local cursor = api.nvim_win_get_cursor(win)
        local row = cursor[1]
        local colorschemeundercursor = arrayOfColorschemes[row]

        api.nvim_command('colorscheme '..colorschemeundercursor)
    end

    --Maybe oneday when it is stable, set colorscheme only for preview window
    --local colorhighlights = api.nvim__get_hl_defs(0)
    --for k,v in pairs(colorhighlights) do
    --    api.nvim_set_hl(previewwin, k, v)
    --end
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

    if plugOpts.hover_colors == true then
        api.nvim_command([[augroup cyclecolo_autocommands]])
        api.nvim_command([[autocmd CursorMoved * lua require('cyclecolo').setPreviewHighlights()]])
        api.nvim_command([[autocmd BufLeave * ColoClose]])
        api.nvim_command([[augroup END]])
    end

    --Map these to the select window, so that when it is deleted the mapping delete as well
    api.nvim_buf_set_keymap(buf, 'n', '<ESC>', ":ColoClose<CR>", {})
    api.nvim_buf_set_keymap(buf, 'n', '<CR>', ":ColoConfirm<CR>", {})

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

    isCycleOpen = false

end


function M.confirm()
    if api.nvim_win_get_buf(0) == buf then
        local currentbackground = vim.opt.background

        --Can set the "variable looping" over here
        local function setColoBasedOnLineContent()
            local cursor = api.nvim_win_get_cursor(win)
            local row = cursor[1]
            local rowContent = api.nvim_buf_get_lines(0, row-1, row, true)
            if rowContent ~= ' ' and rowContent ~= nil then
                api.nvim_command('colorscheme ' .. rowContent[1])
            end
        end
        setColoBasedOnLineContent()

        vim.opt.background = currentbackground

        colorschemeBeforeCycle = nil

        if plugOpts.close_on_confirm == true then
            M.close()
        end
    end

    --Run all attached events through vim.g.cyclecolo_attach_events variable
    for _, event in ipairs(plugOpts.attach_events) do
        vim.api.nvim_command('lua '.. event)
    end

end

return M
