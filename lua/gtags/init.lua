local M = {}

local gtags_cache_dir = vim.fn.stdpath('data') .. '/gtags.nvim/'

local gtags_label = ''

local gtags_global_command = 'global'
local gtags_command = 'gtags'

local notify = require('notify')
local job = require('job')
local logger = require('logger').derive('gtags')

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
    logger.debug(vim.inspect(cmd))
    job.start(cmd, {
        on_exit = function(id, data, single)
            if data > 0 or single > 0 then
                require('notify').notify(
                    'failed to update gtags, exit code:' .. data .. ' single:' .. single,
                    'WarningMsg'
                )
            else
                logger.info('gtags update done')
            end
        end,
    })
end
local global_jobid = -1
local global_result = {}
function M.global(fargs)
    table.insert(fargs, 1, '--result=ctags')
    table.insert(fargs, 1, gtags_global_command)
    global_result = {}
    logger.debug(vim.inspect(fargs))
    global_jobid = require('job').start(fargs, {
        env = {
            GTAGSROOT = vim.fn.getcwd(),
            GTAGSDBPATH = gtags_cache_dir .. path_to_fname(vim.fn.getcwd()),
        },
        on_stdout = function(id, data)
            if id ~= global_jobid then
                return
            end
            for _, v in ipairs(data) do
                logger.info(v)
                table.insert(global_result, v)
            end
        end,
        on_stderr = function(id, data)
            for _, v in ipairs(data) do
                logger.info(v)
            end
        end,
        on_exit = function(id, data, single)
            if id ~= global_jobid then
                return
            end
            logger.info('global exit with code:' .. data .. ' single:' .. single)
            if data == 0 and single == 0 then
                vim.fn.setqflist({}, 'r', { lines = global_result, efm = [[%m\t%f\t%l]] })
            end
        end,
    })
    logger.info('gtags jobid:' .. global_jobid)
end

function M.setup(opts)
    opts = opts or {}

    if opts.gtags_command then
        gtags_command = opts.gtags_command
    end

    if vim.fn.executable(gtags_command) == 0 then
        require('notify').notify(
            string.format('gtags.nvim: %s is not executable', gtags_command),
            'WarningMsg'
        )
        return
    end

    if opts.auto_update then
        vim.api.nvim_create_autocmd({ 'BufWritePost' }, {
            group = vim.api.nvim_create_augroup('gtags.nvim', { clear = true }),
            pattern = { '*' },
            callback = function(_)
                M.update(true)
            end,
        })
    end

    -- local version = vim.split(matchstr(split(system('gtags --version'), '\n')[0], '[0-9]\+\.[0-9]\+'), '\.')
end

return M
