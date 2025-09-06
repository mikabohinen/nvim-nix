{ pkgs, lib }:

let
  utils = import ./utils.nix { inherit lib; };
  languages = import ../config/languages.nix { inherit pkgs lib; };
  plugins = import ../config/plugins.nix { inherit pkgs lib; };

  components = utils.extractComponents languages;

  allTools = components.languageServers ++ components.formatters;

  luaDiagnostics = pkgs.writeText "diagnostics.lua"
    (builtins.readFile ../config/lua/diagnostics.lua);

  luaLsp = pkgs.writeText "lsp.lua" ''
    local lspconfig = require('lspconfig')
    ${utils.generateLspSetup languages}
    ${builtins.readFile ../config/lua/lsp.lua}
  '';

  luaTreesitter = pkgs.writeText "treesitter.lua"
    (builtins.readFile ../config/lua/treesitter.lua);

  nixpkgsPlugins = with pkgs.vimPlugins; [
    nvim-lspconfig
    (nvim-treesitter.withPlugins (p: builtins.map (name: p.${name}) components.treesitterParsers))
    nvim-treesitter-textobjects
  ];

  neovimConfig = pkgs.writeText "init.lua" ''
    -- Source vimrc first
    vim.cmd.source('${../config/vimrc.vim}')

    -- Load lua files
    dofile('${luaDiagnostics}')
    dofile('${luaLsp}')
    dofile('${luaTreesitter}')

    -- Load user configuration if it exists
    pcall(require, 'user')
  '';

  neovim = pkgs.wrapNeovim pkgs.neovim {
    configure = {
      customRC = "lua dofile('${neovimConfig}')";
      packages.myVimPackage = {
        # Plugins that auto-load on startup
        start = nixpkgsPlugins ++ plugins;

        # Optional plugins (load with :packadd)
	# Currently don't have anything here but if there is a good reason
	# to add something here then we could do that
        opt = [];
      };
    };
    extraMakeWrapperArgs = "--prefix PATH : ${pkgs.lib.makeBinPath allTools}";
  };
in
neovim
