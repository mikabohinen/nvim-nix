# default.nix
# Main package definition for nvim-nix

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

    -- LSP setup
    local lspconfig = require('lspconfig')
    ${generateLspSetup supportedLanguages}

    -- LSP keybindings
    vim.api.nvim_create_autocmd('LspAttach', {
      callback = function(event)
        local opts = { buffer = event.buf, silent = true }
        vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
        vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
        vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
        vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
        vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts)
        vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, opts)
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

  # Desktop entry
  desktopItem = pkgs.makeDesktopItem {
    name = "nvim";
    desktopName = "Neovim";
    genericName = "Text Editor";
    comment = "Edit text files";
    exec = "nvim %F";
    icon = "nvim";
    terminal = true;
    categories = [ "Utility" "TextEditor" "Development" ];
    mimeTypes = [
      "text/plain" "text/x-markdown" "text/markdown" "text/x-tex"
      "text/x-chdr" "text/x-csrc" "text/x-c++hdr" "text/x-c++src"
      "text/x-java" "text/x-python" "application/x-shellscript"
    ];
  };

in
{
  # Export individual components for modules
  inherit languageServers formatters extraTools;

  # Export plugin system
  localPlugins = plugins.plugins;  # Built plugin derivations
  pluginUtils = pluginManagement.makePluginUtils plugins.pluginSources nixpkgsPluginNames;

  # Package variants
  neovim = neovimBase;
  full = pkgs.symlinkJoin {
    name = "neovim-with-tools";
    paths = [ neovimFull desktopItem ];
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
