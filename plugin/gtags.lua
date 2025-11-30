vim.api.nvim_create_user_command('Gtags', function(opt)

    require('gtags').run(opt.fargs)

end, { nargs = '*' })
