local M = {}
local api = vim.api

-------------------------

local arrayOfColorschemes = vim.fn.getcompletion('', 'color')
local previewbuf
local previewwin
local buf
local win

-----------------
--Option Defaults
-----------------

local windowBlend
if vim.g.cyclecolo_window_blend == nil then
    windowBlend = 5
end

local closeOnConfirm
if vim.g.cyclecolo_close_on_confirm == nil then
    closeOnConfirm = false
else
    closeOnConfirm = vim.g.cyclecolo_close_on_confirm
end

local previewColors
if vim.g.cyclecolo_preview_colors == nil then
    previewColors = false
else
    previewColors = vim.g.cyclecolo_preview_colors
end

local function previewStringToTable(string)
    local result = {};
    for match in (string..'\n'):gmatch("(.-)"..'\n') do
        table.insert(result, match);
    end
    return result;
end

local previewText
if vim.g.cyclecolo_preview_text == nil then
    local rawText = [[local function themePreview()
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
    previewText = previewStringToTable(rawText)
else
    previewText = previewStringToTable(vim.g.cyclecolo_preview_text)
end

local previewTextSyntax
if vim.g.cyclecolo_preview_text_syntax == nil then
    previewTextSyntax = 'lua'
else
    previewTextSyntax = vim.g.cyclecolo_preview_text_syntax
end

local attachEvents
if vim.g.cyclecolo_attach_events == nil then
    attachEvents = {}
else
    attachEvents = vim.g.cyclecolo_attach_events
end

-----------------
--Window Creation
-----------------


local createdSelect = false
local function createSelectWindow(opts)
    buf = api.nvim_create_buf(false, true)
    win = api.nvim_open_win(buf, true, opts)

    api.nvim_win_set_option(win, 'winhl', 'Normal:Normal')
    api.nvim_win_set_option(win, 'winblend', windowBlend)
    api.nvim_buf_set_lines(buf, 0, 1, true, arrayOfColorschemes)
    createdSelect = true
end

local createdPreview = false
local function createPreviewWindow(opts)
    previewbuf = api.nvim_create_buf(false, true)
    previewwin = api.nvim_open_win(previewbuf, false, opts)

    api.nvim_win_call(previewwin, loadstring('vim.opt.syntax = "'.. previewTextSyntax ..'"'))
    api.nvim_win_set_option(previewwin, 'winhl', 'Normal:Normal')
    api.nvim_win_set_option(win, 'winblend', windowBlend)
    api.nvim_buf_set_lines(previewbuf, 0, 1, true, previewText)
    createdPreview = true
end


----------------
--Preview Colors
----------------


local colorschemeBeforeCycle
function M.setPreviewHighlights()
    if api.nvim_win_get_buf(0) == buf and previewColors == true then
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


function M.setup()
    vim.cmd([[
        command! ColoOpen lua require('cyclecolo').open()
        command! ColoClose lua require('cyclecolo').close()
        command! ColoToggle lua require('cyclecolo').toggle()
        command! ColoConfirm lua require('cyclecolo').confirm()
    ]])
end

local isCycleOpen = false

function M.toggle()
    if isCycleOpen == true then
        M.close()
    else
        M.open()
    end
end

function M.open()

    if (vim.o.columns < 55) then
        local width = math.floor( vim.o.columns * 0.9 )
        local height = math.floor( vim.o.lines * 0.8 )

        local position = {
            row = math.floor( (vim.o.lines - height)/2 - 1 ),
            col = math.floor( (vim.o.columns - width)/2 - 1 )
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
            row = math.floor( (vim.o.lines - height)/2 - 1 ),
            col = 0 + padding
        }
        local previewposition = {
            row = math.floor( (vim.o.lines - height)/2 - 1 ),
            --col = math.floor( (vim.o.columns - width) ) - padding
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

    --api.nvim_command('call feedkeys("/", "n")')

    --Preview autocmd
    api.nvim_command([[augroup cyclecolo_autocommands]])
    api.nvim_command([[autocmd CursorMoved * lua require('cyclecolo').setPreviewHighlights()]])
    api.nvim_command([[autocmd BufLeave * ColoClose]])
    api.nvim_command([[augroup END]])

    --Confirm mapping
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

    api.nvim_command([[augroup cyclecolo_autocommands]])
    api.nvim_command([[autocmd!]])
    api.nvim_command([[augroup END]])

    isCycleOpen = false
end


function M.confirm()
    if api.nvim_win_get_buf(0) == buf then
        local currentbackground = vim.opt.background

        local function setColoBasedOnCursorLine()
            local cursor = api.nvim_win_get_cursor(win)
            local row = cursor[1]
            api.nvim_command('colorscheme ' .. arrayOfColorschemes[row])
        end
        setColoBasedOnCursorLine()

        vim.opt.background = currentbackground

        colorschemeBeforeCycle = nil

        if closeOnConfirm == true then
            M.close()
        end
    end

    --Run all attached events through vim.g.cyclecolo_attach_events variable
    for _, event in ipairs(attachEvents) do
        vim.api.nvim_command('lua '.. event)
    end

end

return M
