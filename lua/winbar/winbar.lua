local M = {}

local status_web_devicons_ok, web_devicons = pcall(require, 'nvim-web-devicons')
local opts = require('winbar.config').options
local f = require('winbar.utils')

local hl_winbar_path = 'WinBarPath'
local hl_winbar_file = 'WinBarFile'
local hl_winbar_symbols = 'WinBarSymbols'
local hl_winbar_file_icon = 'WinBarFileIcon'



-- get path string
local winbar_file = function()
    local file_path = vim.fn.expand('%:~:.:h')
    local offset =50
    local win_width = vim.fn.winwidth(0)
    local full_path_len = string.len(vim.fn.expand('%:p:h')) + offset
    local home_path_len = string.len(vim.fn.expand('%:~:h')) + offset

    if opts.path_style == 'auto' then
        if (full_path_len > win_width) then

            if (home_path_len > win_width) then
                file_path = vim.fn.expand('%:.:h')
            else
                file_path = vim.fn.expand('%:~:h')
            end
        else
            file_path = vim.fn.expand('%:p:h')
        end
    elseif opts.path_style == '/' then
        file_path = vim.fn.expand('%:p:h')
    elseif opts.path_style == '~' then
        file_path = vim.fn.expand('%:~:h')
    elseif opts.path_style == '.' then
        file_path = vim.fn.expand('%:.:h')
    end



    -- local file_path = vim.fn.expand('%:~:.:h')
    local filename = vim.fn.expand('%:t')
    local file_type = vim.fn.expand('%:e')
    local value = ''
    local file_icon = ''

    -- remove '.' and '/'
    file_path = file_path:gsub('^%.', '')
    file_path = file_path:gsub('^%/', '')

    if not f.isempty(filename) then
        local default = false

        if f.isempty(file_type) then
            file_type = ''
            default = true
        end

        if status_web_devicons_ok then
            file_icon = web_devicons.get_icon(filename, file_type, { default = default })
            hl_winbar_file_icon = "WinbarDevIcon" .. file_type --好像会和nvim-tree的图标颜色冲突，换一个颜色组
        end

        if not file_icon then
            file_icon = opts.icons.file_icon_default
        end

        file_icon = '%#' .. hl_winbar_file_icon .. '#' .. file_icon .. ' %*'


        value = ' '
        if opts.show_file_path then
            local file_path_list = {}
            local _ = string.gsub(file_path, '[^/]+', function(w)
                table.insert(file_path_list, w)
            end)

            for i = 1, #file_path_list do
                value = value .. '%#' .. hl_winbar_path .. '#' .. file_path_list[i] .. ' ' .. opts.icons.seperator .. ' %*'
            end
        end
        value = value .. file_icon
        value = value .. '%#' .. hl_winbar_file .. '#' .. filename .. '%*'
    end

    value = '▊' .. value
    return value
end

local _, gps = pcall(require, 'nvim-gps')
local winbar_gps = function()
    local status_ok, gps_location = pcall(gps.get_location, {})
    local value = ''

    if status_ok and gps.is_available() and gps_location ~= 'error' and not f.isempty(gps_location) then
        value = '%#' .. hl_winbar_symbols .. '# ' .. opts.icons.seperator .. ' %*'
        value = value .. '%#' .. hl_winbar_symbols .. '#'  .. gps_location .. '%*'
    end

    return value
end

local excludes = function()
    if vim.tbl_contains(opts.exclude_filetype, vim.bo.filetype) then
        vim.opt_local.winbar = nil
        return true
    end

    return false
end

M.init = function()
    local bgcolor = opts.colors.bg
    vim.cmd('highlight WinBar guibg='..bgcolor)
    if f.isempty(opts.colors.path) then
        hl_winbar_path = 'MsgArea'
    else
        vim.api.nvim_set_hl(0, hl_winbar_path, { fg = opts.colors.path,italic = true,bg = bgcolor})
        -- can also set bg
    end
    if f.isempty(opts.colors.file_name) then
        hl_winbar_file = 'String'
    else
        vim.api.nvim_set_hl(0, hl_winbar_file, { fg = opts.colors.file_name,italic = true,bg = bgcolor })
    end

    if f.isempty(opts.colors.symbols) then
        hl_winbar_symbols = 'Function'
    else
        vim.api.nvim_set_hl(0, hl_winbar_symbols, { fg = opts.colors.symbols,bg = '#ffffff'})
    end
end

M.show_winbar = function()
    if excludes() then
        return
    end

    local value = winbar_file()
    -- 由于文件会变，这个颜色高亮要一直改，不能只在init里改
    if f.isempty(opts.colors.symbols) then
    else
        vim.api.nvim_set_hl(0, hl_winbar_file_icon, { fg = opts.colors.icon,bg = opts.colors.bg })
    end

    if opts.show_symbols then
        if not f.isempty(value) then
            local gps_value = winbar_gps()
            value = value .. gps_value
        end
    end

    --local status_ok, _ = pcall(vim.api.nvim_set_option_value, 'winbar', value, { scope = 'local' })
    local status_ok, _ = pcall(vim.api.nvim_set_option_value, 'winbar', value, { scope = 'local' })
    if not status_ok then
        return
    end
end


return M
