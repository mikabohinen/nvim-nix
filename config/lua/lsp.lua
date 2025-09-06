vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(event)
    local opts = { buffer = event.buf, silent = true }
    local client = vim.lsp.get_client_by_id(event.data.client_id)

    -- Enable omnifunc integration
    if client then
      vim.bo[event.buf].omnifunc = 'v:lua.vim.lsp.omnifunc'
    end

    -- Core LSP navigation
    vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
    vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
    vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
    vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
    vim.keymap.set('n', 'gy', vim.lsp.buf.type_definition, opts)
    vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
    vim.keymap.set('n', '<leader>ck', vim.lsp.buf.signature_help, opts)

    -- Code actions
    vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, opts)
    vim.keymap.set('v', '<leader>ca', vim.lsp.buf.code_action, opts)
    vim.keymap.set('n', '<leader>cr', vim.lsp.buf.rename, opts)

    -- Diagnostic navigation
    vim.keymap.set('n', ']d', function()
      vim.diagnostic.jump({ count = 1 })
    end, opts)
    vim.keymap.set('n', '[d', function()
      vim.diagnostic.jump({ count = -1 })
    end, opts)
    vim.keymap.set('n', ']D', function()
      vim.diagnostic.jump({ count = 1, severity = vim.diagnostic.severity.ERROR })
    end, opts)
    vim.keymap.set('n', '[D', function()
      vim.diagnostic.jump({ count = -1, severity = vim.diagnostic.severity.ERROR })
    end, opts)

    -- Diagnostic display
    vim.keymap.set('n', '<leader>cdf', vim.diagnostic.open_float, opts)
    vim.keymap.set('n', '<leader>cdF', _G.open_focusable_diagnostic, opts)
    vim.keymap.set('n', '<leader>cdl', vim.diagnostic.setloclist, opts)
    vim.keymap.set('n', '<leader>cdq', vim.diagnostic.setqflist, opts)

    -- Diagnostic utilities
    vim.keymap.set('n', '<leader>cds', function()
      local diagnostics = vim.diagnostic.get(0)
      local counts = { ERROR = 0, WARN = 0, HINT = 0, INFO = 0 }
      for _, diag in ipairs(diagnostics) do
        local severity = vim.diagnostic.severity[diag.severity]
        if severity and counts[severity] then  -- Fixed: check for nil
          counts[severity] = counts[severity] + 1
        end
      end
      vim.notify(string.format("Diagnostics: %d errors, %d warnings, %d hints, %d info",
        counts.ERROR or 0, counts.WARN or 0, counts.HINT or 0, counts.INFO or 0))
    end, opts)

    vim.keymap.set('n', '<leader>cdt', function()
      local config = vim.diagnostic.config()
      local virtual_text = config and config.virtual_text  -- Fixed: check for nil
      vim.diagnostic.config({ virtual_text = not virtual_text })
      vim.notify("Virtual text " .. (virtual_text and "disabled" or "enabled"))
    end, opts)

    -- Workspace management
    vim.keymap.set('n', '<leader>wa', vim.lsp.buf.add_workspace_folder, opts)
    vim.keymap.set('n', '<leader>wr', vim.lsp.buf.remove_workspace_folder, opts)
    vim.keymap.set('n', '<leader>wl', function()
      local folders = vim.lsp.buf.list_workspace_folders()
      if folders and #folders > 0 then
        vim.notify(vim.inspect(folders))
      else
        vim.notify("No workspace folders")
      end
    end, opts)
  end,
})
