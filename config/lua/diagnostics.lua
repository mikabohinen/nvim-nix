vim.diagnostic.config({
  virtual_text = false,
  signs = true,
  underline = true,
  update_in_insert = false,
  severity_sort = true,
  float = {
    border = 'rounded',
    source = 'if_many',
    focusable = false,
    close_events = { "BufLeave", "CursorMoved", "InsertEnter", "FocusLost" },
    style = 'minimal',
    max_width = 80,
    max_height = 20,
    wrap = true,
  },
})

-- Custom focusable diagnostic function
local function open_focusable_diagnostic()
  local diagnostics = vim.diagnostic.get(0, { lnum = vim.fn.line('.') - 1 })
  if #diagnostics == 0 then
    vim.notify("No diagnostics on current line", vim.log.levels.INFO)
    return
  end

  local lines = {}
  for _, diag in ipairs(diagnostics) do
    local severity = vim.diagnostic.severity[diag.severity]
    table.insert(lines, string.format("[%s] %s", severity, diag.message))
    if diag.source then
      table.insert(lines, string.format("Source: %s", diag.source))
    end
    table.insert(lines, "")
  end

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.bo[buf].bufhidden = 'wipe'

  local win = vim.api.nvim_open_win(buf, true, {
    relative = 'cursor',
    width = math.min(80, vim.o.columns - 4),
    height = math.min(#lines, 15),
    row = 1,
    col = 0,
    border = 'rounded',
    style = 'minimal',
  })

  vim.keymap.set('n', 'q', '<cmd>close<cr>', { buffer = buf, noremap = true, silent = true })

  -- Auto-close on buffer leave
  vim.api.nvim_create_autocmd("BufLeave", {
    buffer = buf,
    once = true,
    callback = function()
      if vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_close(win, true)
      end
    end
  })
end

-- Make function available globally
_G.open_focusable_diagnostic = open_focusable_diagnostic

-- Set up better diagnostic highlights
vim.api.nvim_set_hl(0, 'DiagnosticSignError', { fg = '#ff6b6b' })
vim.api.nvim_set_hl(0, 'DiagnosticSignWarn', { fg = '#ffa500' })
vim.api.nvim_set_hl(0, 'DiagnosticSignInfo', { fg = '#87ceeb' })
vim.api.nvim_set_hl(0, 'DiagnosticSignHint', { fg = '#98fb98' })

-- Floating window styling
vim.api.nvim_set_hl(0, 'NormalFloat', { fg = 'White', bg = '#2d2d2d' })
vim.api.nvim_set_hl(0, 'FloatBorder', { fg = '#666666', bg = '#2d2d2d' })
