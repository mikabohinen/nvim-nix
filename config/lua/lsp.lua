vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(event)
    local opts = { buffer = event.buf, silent = true }
    local client = vim.lsp.get_client_by_id(event.data.client_id)

    -- Enable omnifunc integration
    if client then
      vim.bo[event.buf].omnifunc = 'v:lua.vim.lsp.omnifunc'
    end

    -- Helper function to create buffer-local commands
    local function buf_command(name, cmd, desc)
      vim.api.nvim_buf_create_user_command(event.buf, name, cmd, { desc = desc })
    end

    vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
    vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
    vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
    vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
    vim.keymap.set('n', 'gy', vim.lsp.buf.type_definition, opts)
    vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)

    -- Diagnostic navigation (follows ][ pattern)
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

    -- LSP administrative operations
    buf_command('LspHover', function() vim.lsp.buf.hover() end, 'Show hover documentation')
    buf_command('LspSig', function() vim.lsp.buf.signature_help() end, 'Show signature help')
    buf_command('LspAction', function() vim.lsp.buf.code_action() end, 'Show code actions')
    buf_command('LspRename', function() vim.lsp.buf.rename() end, 'Rename symbol')

    -- Workspace management
    buf_command('WorkspaceAdd', function() vim.lsp.buf.add_workspace_folder() end, 'Add workspace folder')
    buf_command('WorkspaceRemove', function() vim.lsp.buf.remove_workspace_folder() end, 'Remove workspace folder')
    buf_command('WorkspaceList', function()
      local folders = vim.lsp.buf.list_workspace_folders()
      if folders and #folders > 0 then
        vim.notify(vim.inspect(folders))
      else
        vim.notify("No workspace folders")
      end
    end, 'List workspace folders')
  end,
})
