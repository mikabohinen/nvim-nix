{ pkgs, ... }:

let
  languages = import ./lib/languages.nix { inherit pkgs; };
  inherit (languages) supportedLanguages extractComponents generateLspSetup extraTools;

  plugins = import ./plugins.nix { inherit pkgs lib; };
  pluginManagement = import ./lib/plugin-management.nix { inherit pkgs lib; };

  # Validate plugins
  _ = assert pluginManagement.validateAllPlugins plugins.pluginSources; null;

  components = extractComponents supportedLanguages;
  inherit (components) languageServers treesitterParsers formatters;
  lib = pkgs.lib;

  allDevTools = languageServers ++ formatters ++ extraTools;

  vimrcConfig = pkgs.writeText "vimrc" (builtins.readFile ./vimrc.vim);

  nixpkgsPlugins = with pkgs.vimPlugins; [
    nvim-lspconfig
    (nvim-treesitter.withPlugins (p: builtins.map (name: p.${name}) treesitterParsers))
    nvim-treesitter-textobjects
  ];

  nixpkgsPluginNames = map (plugin:
    if plugin ? pname then plugin.pname
    else if plugin ? name then plugin.name
    else "unknown-plugin"
  ) nixpkgsPlugins;

  totalPluginCount = plugins.utils.pluginCount + (lib.length nixpkgsPlugins);

  neovimConfig = pkgs.writeText "init.lua" ''
    -- Source the vimrc first
    vim.cmd.source('${vimrcConfig}')


    -- Configure diagnostics display
    vim.diagnostic.config({
      virtual_text = false,
      signs = true,
      underline = true,
      update_in_insert = false,
      severity_sort = true,
      float = {
        border = 'single',
        source = 'always',
        header = "",
        prefix = "",
        focusable = false,
        close_events = { "BufLeave", "CursorMoved", "InsertEnter", "FocusLost" },
        style = 'minimal',
        max_width = 80,
        max_height = 20,
	pad_top = 0,
        pad_bottom = 0,
        wrap = true,
      },
    })

    local function open_focusable_diagnostic()
      -- First, open a non-focusable float to get diagnostics
      local diagnostics = vim.diagnostic.get(0, { lnum = vim.fn.line('.') - 1 })
      if #diagnostics == 0 then
        print("No diagnostics on current line")
        return
      end

      -- Create the focusable float window manually for more control
      local buf = vim.api.nvim_create_buf(false, true)
      local diagnostic_text = {}

      for _, diag in ipairs(diagnostics) do
        local severity = vim.diagnostic.severity[diag.severity]
        table.insert(diagnostic_text, string.format("[%s] %s", severity, diag.message))
        if diag.source then
          table.insert(diagnostic_text, string.format("Source: %s", diag.source))
        end
        table.insert(diagnostic_text, "") -- blank line between diagnostics
      end

      vim.api.nvim_buf_set_lines(buf, 0, -1, false, diagnostic_text)

      local win = vim.api.nvim_open_win(buf, true, {
        relative = 'cursor',
        width = math.min(100, vim.o.columns - 4),
        height = math.min(#diagnostic_text, 20),
        row = 1,
        col = 0,
        border = 'single',
        style = 'minimal',
      })

      vim.api.nvim_buf_set_option(buf, 'modifiable', false)
      vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')

      vim.api.nvim_buf_set_keymap(buf, 'n', 'q', '<cmd>close<cr>', { noremap = true, silent = true })

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

    -- Custom diagnostic highlights for better visibility
    vim.api.nvim_set_hl(0, 'DiagnosticFloatingError', {
      fg = '#ff6b6b', bg = 'NONE', bold = true
    })
    vim.api.nvim_set_hl(0, 'DiagnosticFloatingWarn', {
      fg = '#ffa500', bg = 'NONE', bold = true
    })
    vim.api.nvim_set_hl(0, 'DiagnosticFloatingInfo', {
      fg = '#87ceeb', bg = 'NONE'
    })
    vim.api.nvim_set_hl(0, 'DiagnosticFloatingHint', {
      fg = '#98fb98', bg = 'NONE'
    })

    -- Floating window background
    vim.api.nvim_set_hl(0, 'NormalFloat', {
      fg = 'White', bg = '#2d2d2d'
    })
    vim.api.nvim_set_hl(0, 'FloatBorder', {
      fg = '#666666', bg = '#2d2d2d'
    })

    -- Sign column diagnostics
    vim.api.nvim_set_hl(0, 'DiagnosticSignError', {
      fg = '#ff6b6b', bg = 'NONE'
    })
    vim.api.nvim_set_hl(0, 'DiagnosticSignWarn', {
      fg = '#ffa500', bg = 'NONE'
    })
    vim.api.nvim_set_hl(0, 'DiagnosticSignInfo', {
      fg = '#87ceeb', bg = 'NONE'
    })
    vim.api.nvim_set_hl(0, 'DiagnosticSignHint', {
      fg = '#98fb98', bg = 'NONE'
    })

    -- LSP setup
    local lspconfig = require('lspconfig')
    ${generateLspSetup supportedLanguages}

    -- LSP keybindings
    vim.api.nvim_create_autocmd('LspAttach', {
      callback = function(event)
        local opts = { buffer = event.buf, silent = true }
        local client = vim.lsp.get_client_by_id(event.data.client_id)

	-- Enable omnifunc integration
	vim.bo[event.buf].omnifunc = 'v:lua.vim.lsp.omnifunc'

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

        -- Diagnostic navigation (buffer-local)
        vim.keymap.set('n', ']d', vim.diagnostic.goto_next, opts)
        vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, opts)
        vim.keymap.set('n', ']D', function()
          vim.diagnostic.goto_next({ severity = vim.diagnostic.severity.ERROR })
        end, opts)
        vim.keymap.set('n', '[D', function()
          vim.diagnostic.goto_prev({ severity = vim.diagnostic.severity.ERROR })
        end, opts)

        -- Diagnostic display (buffer-local)
        vim.keymap.set('n', '<leader>cdf', vim.diagnostic.open_float, { desc = 'Show diagnostic float (quick peek)' })
        vim.keymap.set('n', '<leader>cdF', open_focusable_diagnostic, { desc = 'Show diagnostic float (scrollable)' })
        vim.keymap.set('n', '<leader>cdl', vim.diagnostic.setloclist, { desc = 'Diagnostics to location list' })
        vim.keymap.set('n', '<leader>cdq', vim.diagnostic.setqflist, { desc = 'Diagnostics to quickfix' })
        vim.keymap.set('n', '<leader>cds', function()
          local diagnostics = vim.diagnostic.get(0)
          local errors = vim.tbl_filter(function(d) return d.severity == vim.diagnostic.severity.ERROR end, diagnostics)
          local warnings = vim.tbl_filter(function(d) return d.severity == vim.diagnostic.severity.WARN end, diagnostics)
          local hints = vim.tbl_filter(function(d) return d.severity == vim.diagnostic.severity.HINT end, diagnostics)
          print(string.format("Diagnostics: %d errors, %d warnings, %d hints", #errors, #warnings, #hints))
        end, { desc = 'Show diagnostic summary' })
        vim.keymap.set('n', '<leader>cdt', function()
          local config = vim.diagnostic.config()
          vim.diagnostic.config({ virtual_text = not config.virtual_text })
          print("Virtual text " .. (config.virtual_text and "disabled" or "enabled"))
        end, { desc = 'Toggle virtual text' })

        -- Workspace management (LSP-specific)
        vim.keymap.set('n', '<leader>wa', vim.lsp.buf.add_workspace_folder, opts)
        vim.keymap.set('n', '<leader>wr', vim.lsp.buf.remove_workspace_folder, opts)
        vim.keymap.set('n', '<leader>wl', function()
          print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
        end, opts)
      end,
    })

    -- Treesitter configuration
    require('nvim-treesitter.configs').setup({
      ensure_installed = {},
      highlight = { enable = true, additional_vim_regex_highlighting = false },
      incremental_selection = {
        enable = true,
        keymaps = {
          init_selection = "gnn",
          node_incremental = "grn",
          scope_incremental = "grc",
          node_decremental = "grm",
        },
      },
      textobjects = {
        select = {
          enable = true,
          lookahead = true,
          keymaps = {
            ["af"] = "@function.outer", ["if"] = "@function.inner",
            ["ac"] = "@class.outer", ["ic"] = "@class.inner",
            ["al"] = "@loop.outer", ["il"] = "@loop.inner",
            ["aa"] = "@parameter.outer", ["ia"] = "@parameter.inner",
          },
        },
        move = {
          enable = true,
          set_jumps = true,
          goto_next_start = { ["]f"] = "@function.outer", ["]c"] = "@class.outer" },
          goto_next_end = { ["]F"] = "@function.outer", ["]C"] = "@class.outer" },
          goto_previous_start = { ["[f"] = "@function.outer", ["[c"] = "@class.outer" },
          goto_previous_end = { ["[F"] = "@function.outer", ["[C"] = "@class.outer" },
        },
      },
    })

    -- Load user configuration if it exists
    pcall(require, 'user')
  '';

  # Base neovim package with proper plugin integration
  neovimBase = pkgs.wrapNeovim pkgs.neovim {
    viAlias = true;
    vimAlias = true;
    configure = {
      customRC = "lua dofile('${neovimConfig}')";
      packages.myVimPackage = {
        # Plugins that auto-load on startup
        start = nixpkgsPlugins ++ plugins.pluginList;

        # Optional plugins (load with :packadd)
        opt = [];
      };
    };
  };

  # Full package with development tools in PATH
  neovimFull = pkgs.symlinkJoin {
    name = "neovim-full";
    paths = [ neovimBase ];
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/nvim \
        --prefix PATH : ${pkgs.lib.makeBinPath allDevTools}

      # Also wrap vi and vim if they exist
      for cmd in vi vim; do
        if [ -f "$out/bin/$cmd" ]; then
          wrapProgram "$out/bin/$cmd" \
            --prefix PATH : ${pkgs.lib.makeBinPath allDevTools}
        fi
      done
    '';
  };
in
{
  inherit languageServers formatters extraTools;

  localPlugins = plugins.plugins;
  pluginUtils = pluginManagement.makePluginUtils plugins.pluginSources nixpkgsPluginNames;

  # Package variants
  neovim = neovimBase;
  full = pkgs.symlinkJoin {
    name = "neovim-with-tools";
    paths = [ neovimFull ];
  };

  # Utility functions
  withTools = tools: pkgs.symlinkJoin {
    name = "neovim-custom";
    paths = [ neovimBase ];
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/nvim \
        --prefix PATH : ${pkgs.lib.makeBinPath tools}
    '';
  };

  # Development environment
  devEnv = pkgs.buildEnv {
    name = "neovim-dev-env";
    paths = allDevTools ++ [ neovimFull ];
  };

  # Plugin management info and utilities
  pluginInfo = {
    sources = plugins.pluginSources;
    builtPlugins = plugins.plugins;
    utils = plugins.utils;

    # Plugin categorization
    localPlugins = builtins.attrNames plugins.pluginSources;
    nixpkgsPlugins = nixpkgsPluginNames;

    # Plugin counts
    localPluginCount = plugins.utils.pluginCount;
    nixpkgsPluginCount = lib.length nixpkgsPlugins;
    totalPluginCount = totalPluginCount;

    # Other info
    supportedLanguages = builtins.attrNames supportedLanguages;
    devShell = pluginManagement.makePluginDevShell plugins.pluginSources nixpkgsPluginNames;
  };
}
