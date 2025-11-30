local M = {}

local gtags_cache_dir = vim.fn.stdpath('data') .. '/gtags.nvim/'

local gtags_label = ''

---@param p string
local function path_to_fname(p)
    return p:gsub('/', '_'):gsub('\\', '_'):gsub(':', '_')
end

function M.update(single_update)
    local dir = gtags_cache_dir .. path_to_fname(vim.fn.getcwd())

    local cmd = { 'gtags' }

    if #gtags_label > 0 then
        table.insert(cmd, '--gtagslabel=' .. gtags_label)
    end

    if single_update and vim.fn.filereadable(dir .. '/GTAGS') == 1 then
        table.insert(cmd, '--single-update')
        table.insert(cmd, vim.fn.expand('%:p'))
    else
        table.insert(cmd, '--skip-unreadable')
    end

    if vim.fn.isdirectory(dir) == 0 then
        vim.fn.mkdir(dir, 'p')
    end

    table.insert(cmd, '-O')
    table.insert(cmd, dir)

    require('job').start(cmd, {
        on_exit = function(id, data, single)
            if data > 0 or single > 0 then
                require('notify').notify(
                    'failed to update gtags, exit code:' .. data .. ' single:' .. single,
                    'WarningMsg'
                )
            end
        end,
    })
end

function M.run(fargs) end

function M.setup(opts) end

return M
