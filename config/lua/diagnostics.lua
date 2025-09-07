vim.diagnostic.config({
  virtual_text = false,
  signs = true,
  underline = true,
  update_in_insert = false,
  severity_sort = true,
  float = {
    border = 'rounded',
    source = 'if_many',
    focusable = true,
    style = 'minimal',
    max_width = 80,
    max_height = 20,
    wrap = true,
  },
})

vim.api.nvim_set_hl(0, 'DiagnosticSignError', { link = 'Error' })
vim.api.nvim_set_hl(0, 'DiagnosticSignWarn', { link = 'WarningMsg' })
vim.api.nvim_set_hl(0, 'DiagnosticSignInfo', { link = 'Question' })
vim.api.nvim_set_hl(0, 'DiagnosticSignHint', { link = 'Comment' })
