vim.api.nvim_create_user_command('Gtags', function(opt)

    require('gtags').global(opt.fargs)

end, { nargs = '*' })
