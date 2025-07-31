require('treesitter-context').setup()

vim.api.nvim_create_user_command('TSContext', function(args)
  require('treesitter-context.cli').run(args.fargs)
end, {
  complete = function()
    return require('treesitter-context.cli').complete()
  end,
  nargs = '*',
  desc = 'Manage Treesitter Context',
})

vim.api.nvim_set_hl(0, 'TreesitterContext', { link = 'NormalFloat', default = true })
vim.api.nvim_set_hl(0, 'TreesitterContextLineNumber', { link = 'LineNr', default = true })
vim.api.nvim_set_hl(0, 'TreesitterContextBottom', { link = 'NONE', default = true })
vim.api.nvim_set_hl(
  0,
  'TreesitterContextLineNumberBottom',
  { link = 'TreesitterContextBottom', default = true }
)
vim.api.nvim_set_hl(0, 'TreesitterContextSeparator', { link = 'FloatBorder', default = true })
