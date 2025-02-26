{ pkgs, ... }:

let
  # Build custom plugins from source
  customPlugins = {
    # cornelis = pkgs.vimUtils.buildVimPluginFrom2Nix {
    #   pname = "cornelis";
    #   version = cornelis-src.shortRev or "master";
    #   src = cornelis-src;
    # };
  };

  # Language setup - simplified with direct mapping
  supportedLanguages = {
    bash = {
      lsp = {
        package = pkgs.nodePackages.bash-language-server;
        serverName = "bashls";
      };
      treesitter = "bash";
    };
    haskell = {
      lsp = {
        package = pkgs.haskell-language-server;
        serverName = "hls";
      };
      treesitter = "haskell";
    };
    java = {
      lsp = {
        package = pkgs.jdt-language-server;
        serverName = "jdtls";
      };
      treesitter = "java";
    };
    lisp = {
      treesitter = "commonlisp";
    };
    markdown = {
      treesitter = "markdown";
    };
    nix = {
      lsp = {
        package = pkgs.nixd;
        serverName = "nixd";
      };
      treesitter = "nix";
    };
    latex = {
      lsp = {
        package = pkgs.texlab;
        serverName = "texlab";
      };
      treesitter = "latex";
    };
  };

  # Extract language servers and treesitter parsers
  languageServers = builtins.filter 
    (x: x != null) 
    (builtins.map 
      (lang: if builtins.hasAttr "lsp" lang then lang.lsp.package else null) 
      (builtins.attrValues supportedLanguages)
    );
  
  treesitterParsers = builtins.filter 
    (x: x != null) 
    (builtins.map 
      (lang: if builtins.hasAttr "treesitter" lang then lang.treesitter else null) 
      (builtins.attrValues supportedLanguages)
    );
    
  # Generate LSP setup code automatically from the configuration
  lspSetupCode = builtins.concatStringsSep "\n" (
    builtins.map 
      (name: let lang = supportedLanguages.${name}; in
        if builtins.hasAttr "lsp" lang then
          "lspconfig.${lang.lsp.serverName}.setup{}"
        else ""
      )
      (builtins.attrNames supportedLanguages)
  );
  
  # Plugins list
  plugins = with pkgs.vimPlugins; [
    # LSP
    nvim-lspconfig
    
    # Autopairs
    nvim-autopairs
    
    # Syntax/treesitter
    (nvim-treesitter.withPlugins (p: 
      builtins.map (name: p.${name}) treesitterParsers
    ))
    
    # File navigation
    plenary-nvim
    telescope-nvim
    
    # Agda
    cornelis
    
    # Requested extra plugins
    vim-sleuth
    unicode-vim
  ];

  # Neovim configuration
  neovimConfig = pkgs.writeText "init.lua" ''
    -- Basic settings
    vim.opt.number = true
    vim.opt.relativenumber = true
    vim.opt.shiftwidth = 2
    vim.opt.tabstop = 2
    vim.opt.expandtab = true
    vim.opt.termguicolors = true
    
    -- Global settings
    vim.g.mapleader = " "
    vim.g.maplocalleader = ","
    
    -- LSP setup
    local lspconfig = require('lspconfig')
    
    -- Set up language servers (dynamically generated)
    ${lspSetupCode}
    
    -- Format on save
    vim.api.nvim_create_autocmd("BufWritePre", {
      callback = function()
        vim.lsp.buf.format()
      end,
    })
    
    -- Auto-pairs setup
    require('nvim-autopairs').setup{}
    
    -- Telescope setup
    require('telescope').setup{}
    vim.keymap.set('n', '<leader>ff', require('telescope.builtin').find_files)
    vim.keymap.set('n', '<leader>fg', require('telescope.builtin').live_grep)
    vim.keymap.set('n', '<leader>fb', require('telescope.builtin').buffers)
    
    -- User custom configuration for Agda
    vim.cmd 'colorscheme quiet'
    vim.g.cornelis_agda_prefix = "<C-g>"

    -- Set up autocommands for Agda files
    vim.api.nvim_create_autocmd({"BufRead", "BufNewFile"}, {
        pattern = "*.agda",
        callback = function()
            -- Key mappings for Agda files
            local keymaps = {
                {"<leader>l", ":CornelisLoad<CR>"},
                {"<leader>r", ":CornelisRefine<CR>"},
                {"<leader>d", ":CornelisMakeCase<CR>"},
                {"<leader>,", ":CornelisTypeContext<CR>"},
                {"<leader>.", ":CornelisTypeContextInfer<CR>"},
                {"<leader>n", ":CornelisSolve<CR>"},
                {"<leader>a", ":CornelisAuto<CR>"},
                {"<leader>m", ":CornelisMakeCase<CR>"},
                {"gd",        ":CornelisGoToDefinition<CR>"},
                {"[/",        ":CornelisPrevGoal<CR>"},
                {"]/",        ":CornelisNextGoal<CR>"},
                {"<C-A>",     ":CornelisInc<CR>"},
                {"<C-X>",     ":CornelisDec<CR>"}
            }

            -- Apply each keymap
            for _, map in ipairs(keymaps) do
                vim.keymap.set("n", map[1], map[2], { buffer = true })
            end

            vim.fn['cornelis#bind_input']("nat", "ℕ")
        end
    })

    -- Set up autocommand for closing info windows when quitting
    vim.api.nvim_create_autocmd("QuitPre", {
        pattern = "*.agda",
        command = "CornelisCloseInfoWindows"
    })
  '';

  # The final Neovim package
  neovimWrapped = pkgs.wrapNeovim pkgs.neovim {
    viAlias = true;
    vimAlias = true;
    configure = {
      customRC = "lua dofile('${neovimConfig}')";
      packages.myVimPackage = {
        start = plugins;
      };
    };
  };

in
pkgs.symlinkJoin {
  name = "my-neovim";
  paths = [ neovimWrapped ];
  buildInputs = [ pkgs.makeWrapper ];
  
  # Add required runtime dependencies
  postBuild = ''
    wrapProgram $out/bin/nvim \
      --prefix PATH : ${pkgs.lib.makeBinPath (
        languageServers ++ [
          pkgs.ripgrep
          pkgs.fd
        ]
      )}
  '';
}
