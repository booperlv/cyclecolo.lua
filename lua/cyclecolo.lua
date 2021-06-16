local M = {}
local api = vim.api


local arrayOfColorschemes = vim.fn.getcompletion('', 'color')
local previewbuf
local previewwin
local buf
local win

local previewText
if vim.g.cyclecolo_preview_text == nil then
    previewText = {
        'function canYouHearMe(...) {',
        '    console.log("I guess this is also a test")',
        '}'
    }
else
    previewText = vim.g.cyclecolo_preview_text
end

local previewTextSyntax
if vim.g.cyclecolo_preview_text_syntax == nil then
    previewTextSyntax = 'javascript'
else
    previewTextSyntax = vim.g.cyclecolo_preview_text_syntax
end

local function createSelectWindow(opts)
    buf = api.nvim_create_buf(false, true)
    win = api.nvim_open_win(buf, true, opts)

    api.nvim_win_set_option(win, 'winhl', 'Normal:Normal')
    api.nvim_buf_set_lines(buf, 0, 1, true, arrayOfColorschemes)
end

local function createPreviewWindow(opts)
    previewbuf = api.nvim_create_buf(false, true)
    previewwin = api.nvim_open_win(previewbuf, false, opts)

    api.nvim_win_call(previewwin, loadstring('vim.opt.syntax = "'.. previewTextSyntax ..'"'))
    api.nvim_win_set_option(previewwin, 'winhl', 'Normal:Normal')
    api.nvim_buf_set_lines(previewbuf, 0, 1, true, previewText)
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
    isCycleOpen = true

    local currentwinheight = api.nvim_win_get_height(0)
    local currentwinwidth = api.nvim_win_get_width(0)

    local distance = math.floor(currentwinwidth/20)
    local dimensions = {
        width = math.floor((currentwinwidth/2) - distance),
        height = math.floor(currentwinheight - distance) ,
    }
    local position = {
        row = currentwinheight/2 - dimensions.height/2,
        col = (currentwinwidth*0.25 - dimensions.width/2) + distance/4
    }
    local previewposition = {
        row = currentwinheight/2 - dimensions.height/2,
        col = ((currentwinwidth*0.25 - dimensions.width/2) + dimensions.width + distance) - distance/4
    }

    createSelectWindow({
        relative="editor",
        row=position['row'],
        col=position['col'],
        width=dimensions['width'],
        height=dimensions['height'],
        noautocmd=true,
        border='single',
        style='minimal',
    })

    createPreviewWindow({
        relative="editor",
        row=previewposition['row'],
        col=previewposition['col'],
        width=dimensions['width'],
        height=dimensions['height'],
        noautocmd=true,
        border='single',
        style='minimal',
        focusable=false,
    })

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

end

function M.close()
    isCycleOpen = false
    api.nvim_buf_delete(buf, {})
    api.nvim_buf_delete(previewbuf, {})
    vim.opt.modifiable = true
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
    end

    --Run all attached events through vim.g.cyclecolo_attach_events variable
    for _, event in ipairs(vim.g.cyclecolo_attach_events) do
        vim.api.nvim_command('lua '.. event)
    end
end

return M
