{ pkgs, ... }:

let
  sbclWithPackages = pkgs.sbcl.withPackages (ps: with ps; [
    swank # SWANK server for REPL integration
    alexandria # Utility library
    bordeaux-threads # Portable threading
  ]);

  # Language setup
  supportedLanguages = {
    bash = {
      lsp = {
        package = pkgs.nodePackages.bash-language-server;
        serverName = "bashls";
      };
      treesitter = "bash";
      formatter = {
        name = "shfmt";
        package = pkgs.shfmt;
      };
    };
    haskell = {
      lsp = {
        package = pkgs.haskell-language-server;
        serverName = "hls";
      };
      treesitter = "haskell";
      formatter = {
        name = "fourmolu";
        package = pkgs.haskellPackages.fourmolu;
      };
    };
    java = {
      lsp = {
        package = pkgs.jdt-language-server;
        serverName = "jdtls";
      };
      treesitter = "java";
      formatter = {
        name = "google-java-format";
        package = pkgs.google-java-format;
      };
    };
    lisp = {
      treesitter = "commonlisp";
    };
    markdown = {
      treesitter = "markdown";
      formatter = {
        name = "prettier";
        package = pkgs.nodePackages.prettier;
      };
    };
    nix = {
      lsp = {
        package = pkgs.nixd;
        serverName = "nixd";
        settings = {
          nixd = {
            nixpkgs = {
              expr = "import <nixpkgs> { }";
            };
            formatting = {
              command = [ "nixpkgs-fmt" ];
            };
          };
        };
      };
      treesitter = "nix";
      formatter = {
        name = "nixpkgs_fmt";
        package = pkgs.nixpkgs-fmt;
      };
    };
    latex = {
      lsp = {
        package = pkgs.texlab;
        serverName = "texlab";
      };
      treesitter = "latex";
    };
    lua = {
      formatter = {
        name = "stylua";
        package = pkgs.stylua;
      };
    };
    python = {
      lsp = {
        package = pkgs.pyright;
        serverName = "pyright";
      };
      treesitter = "python";
      formatter = {
        name = "black";
        package = pkgs.black;
      };
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

  # Extract formatters
  formatters = builtins.filter
    (x: x != null)
    (builtins.map
      (lang: if builtins.hasAttr "formatter" lang then lang.formatter.package else null)
      (builtins.attrValues supportedLanguages)
    );

  # Generate LSP setup code automatically from the configuration
  lspSetupCode = builtins.concatStringsSep "\n" (
    builtins.map
      (name:
        let lang = supportedLanguages.${name}; in
        if builtins.hasAttr "lsp" lang then
          "lspconfig.${lang.lsp.serverName}.setup{}"
        else ""
      )
      (builtins.attrNames supportedLanguages)
  );

  vimrcConfig = pkgs.writeText "vimrc" (builtins.readFile ./vimrc.vim);

  # Essential plugins only
  plugins = with pkgs.vimPlugins; [
    # LSP integration
    nvim-lspconfig

    # Enhanced syntax highlighting with text objects
    (nvim-treesitter.withPlugins (p:
      builtins.map (name: p.${name}) treesitterParsers
    ))
    nvim-treesitter-textobjects

    # Essential editing
    vim-surround
    vim-vinegar
    vim-repeat

    # Git integration
    vim-fugitive

    # Lisp exception: Vim's text objects and structural editing work so naturally
    # with Lisp's uniform syntax that specialized tools like paredit aren't luxuries
    # - they're baseline usability. Every other language gets LSP + Treesitter.
    vim-sexp
  ];

  neovimConfig = pkgs.writeText "init.lua" ''
    -- Source the vimrc first
    vim.cmd.source('${vimrcConfig}')

    -- Essential Lua configuration - only what vimscript can't handle well

    -- LSP setup (modern necessity)
    local lspconfig = require('lspconfig')
    ${lspSetupCode}

    -- LSP keybindings (attached when LSP is available)
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

    -- Enhanced Treesitter with text objects (Lua-only features)
    require('nvim-treesitter.configs').setup({
      ensure_installed = {},
      highlight = {
        enable = true,
        additional_vim_regex_highlighting = false,
      },
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
            ["af"] = "@function.outer",
            ["if"] = "@function.inner",
            ["ac"] = "@class.outer",
            ["ic"] = "@class.inner",
            ["al"] = "@loop.outer",
            ["il"] = "@loop.inner",
            ["aa"] = "@parameter.outer",
            ["ia"] = "@parameter.inner",
          },
        },
        move = {
          enable = true,
          set_jumps = true,
          goto_next_start = {
            ["]f"] = "@function.outer",
            ["]c"] = "@class.outer",
          },
          goto_next_end = {
            ["]F"] = "@function.outer",
            ["]C"] = "@class.outer",
          },
          goto_previous_start = {
            ["[f"] = "@function.outer",
            ["[c"] = "@class.outer",
          },
          goto_previous_end = {
            ["[F"] = "@function.outer",
            ["[C"] = "@class.outer",
          },
        },
      },
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

  # Create a desktop entry file
  desktopItem = pkgs.makeDesktopItem {
    name = "nvim";
    desktopName = "Neovim";
    genericName = "Text Editor";
    comment = "Edit text files";
    exec = "kitty -e nvim %F";
    icon = "nvim";
    terminal = true;
    categories = [ "Utility" "TextEditor" "Development" ];
    mimeTypes = [
      "text/plain"
      "text/x-markdown"
      "text/markdown"
      "text/x-tex"
      "text/x-chdr"
      "text/x-csrc"
      "text/x-c++hdr"
      "text/x-c++src"
      "text/x-java"
      "text/x-python"
      "application/x-shellscript"
    ];
  };

in
pkgs.symlinkJoin {
  name = "my-neovim";
  paths = [ neovimWrapped desktopItem ];
  buildInputs = [ pkgs.makeWrapper ];

  postBuild = ''
    wrapProgram $out/bin/nvim \
      --prefix PATH : ${pkgs.lib.makeBinPath (
        languageServers ++ formatters ++ [
          pkgs.ripgrep
          pkgs.fd
          pkgs.kitty
          pkgs.git
          sbclWithPackages
          pkgs.rlwrap
          pkgs.python312Packages.flake8
          pkgs.python312Packages.isort
          pkgs.python312Packages.pyupgrade
        ]
      )}
  '';
}
