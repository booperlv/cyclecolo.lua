local M = {}
local api = vim.api

local arrayOfColorschemes = vim.fn.getcompletion('', 'color')
local buf = ''
local win = ''


--Functions to interface with vim


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

    buf = api.nvim_create_buf(false, true)

    local currentwinheight = api.nvim_win_get_height(0)
    local currentwinwidth = api.nvim_win_get_width(0)

    local padding = 10
    local dimensions = {
        width = currentwinwidth - padding,
        height = currentwinheight - padding,
    }
    local position = {
        row = currentwinheight/2 - dimensions.height/2,
        col = currentwinwidth/2 - dimensions.width/2
    }

    win = api.nvim_open_win(buf, true, {
        relative="editor",
        row=position['row'],
        col=position['col'],
        width=dimensions['width'],
        height=dimensions['height'],
        noautocmd=true,
        border='single',
        style='minimal',
    })

    --api.nvim_win_set_width(win, 20)
    api.nvim_buf_set_lines(buf, 0, 1, true, arrayOfColorschemes)
    vim.opt.modifiable = false
end

function M.close()
    isCycleOpen = false
    api.nvim_buf_delete(buf, {})
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
