{ pkgs, ... }:

let
  # Create SBCL with SWANK and other useful packages
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
      tools = [ pkgs.nix-output-monitor pkgs.nix-tree ];
      description = "Nix expression language";
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

  # Read the separate .vimrc file
  vimrcConfig = pkgs.writeText "vimrc" (builtins.readFile ./vimrc.vim);

  # Essential plugins only - following expert minimalism but keeping Lua necessities
  plugins = with pkgs.vimPlugins; [
    # LSP (modern necessity)
    nvim-lspconfig

    # Enhanced syntax highlighting with text objects (Lua-only features)
    (nvim-treesitter.withPlugins (p:
      builtins.map (name: p.${name}) treesitterParsers
    ))
    nvim-treesitter-textobjects # Essential for advanced text manipulation

    # Essential editing (Tim Pope level quality)
    nvim-autopairs
    vim-surround
    vim-vinegar

    # Git integration (genuinely valuable)
    gitsigns-nvim
    vim-fugitive

    # Specialized language support
    cornelis # Agda
    conjure # Common Lisp REPL
    vim-sexp # Lisp structural editing
    vim-sexp-mappings-for-regular-people # Simplified sexp mappings

    # Formatting (external tool integration)
    conform-nvim

    # Colorscheme
    nightfox-nvim

    # Learning aid
    which-key-nvim
  ];

  # Streamlined Neovim configuration - expert level with essential Lua features
  neovimConfig = pkgs.writeText "init.lua" ''
    -- Source the .vimrc first (vim philosophy foundation)
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

    -- Which-key setup (proper Lua configuration for learning aid)
    local wk = require("which-key")
    wk.setup({
      preset = "modern",
      delay = 300,
      expand = 1,
      notify = true,
      win = {
        border = "rounded",
        padding = { 1, 2 },
      },
    })

    -- Register which-key mappings
    wk.add({
      -- Leader key groups
      { "<leader>f", group = "Find" },
      { "<leader>s", group = "Search" },
      { "<leader>b", group = "Buffer" },
      { "<leader>w", group = "Window" },
      { "<leader>g", group = "Git" },
      { "<leader>c", group = "Code" },
      { "<leader>r", group = "Refactor" },

      -- File operations (vim native)
      { "<leader>f", desc = "Find files (:find **/*)" },
      { "<leader>F", desc = "Find files recursive" },

      -- Search operations
      { "<leader>s", desc = "Search in project (:vimgrep)" },
      { "<leader>S", desc = "System grep" },

      -- Buffer operations
      { "<leader>b", desc = "Switch buffer (:buffer)" },
      { "<leader>B", desc = "Switch buffer split" },
      { "[b", desc = "Previous buffer" },
      { "]b", desc = "Next buffer" },
      { "<leader>d", desc = "Delete buffer" },

      -- Quickfix navigation
      { "<leader>q", desc = "Open quickfix" },
      { "<leader>Q", desc = "Close quickfix" },
      { "<leader>l", desc = "Open location list" },
      { "<leader>L", desc = "Close location list" },
      { "]q", desc = "Next quickfix" },
      { "[q", desc = "Previous quickfix" },

      -- Git operations
      { "<leader>gb", desc = "Toggle git blame" },
      { "<leader>gp", desc = "Preview hunk" },
      { "<leader>gr", desc = "Reset hunk" },
      { "<leader>gs", desc = "Stage hunk" },
      { "<leader>gu", desc = "Undo stage hunk" },

      -- Code operations (LSP when available)
      { "<leader>cf", desc = "Format buffer" },
      { "<leader>ca", desc = "Code actions" },
      { "<leader>rn", desc = "Rename symbol" },

      -- Text objects (treesitter)
      { "af", desc = "Around function" },
      { "if", desc = "Inside function" },
      { "ac", desc = "Around class" },
      { "ic", desc = "Inside class" },
      { "]f", desc = "Next function" },
      { "[f", desc = "Previous function" },

      -- Clipboard operations
      { "<leader>y", desc = "Copy to system clipboard" },
      { "<leader>p", desc = "Paste from system clipboard" },
    })

    -- Formatting with conform (external tool integration)
    local conform = require("conform")
    local formatters_by_ft = {
      ["*"] = { "trim_whitespace" }
    }

    ${builtins.concatStringsSep "\n    " (
      builtins.map
        (name: let lang = supportedLanguages.${name}; in
          if builtins.hasAttr "formatter" lang then
            ''formatters_by_ft["${name}"] = { "${lang.formatter.name}" }''
          else ""
        )
        (builtins.attrNames supportedLanguages)
    )}

    conform.setup({
      formatters_by_ft = formatters_by_ft,
      format_on_save = { timeout_ms = 500, lsp_fallback = true },
    })

    -- Manual formatting keybinding
    vim.keymap.set("n", "<leader>cf", function()
      conform.format({ async = true, lsp_fallback = true })
    end, { desc = "Format buffer" })

    -- Essential editing enhancements
    require('nvim-autopairs').setup({
      disable_filetype = { "TelescopePrompt", "vim" },
      enable_check_bracket_line = false, -- Better for Lisp
    })

    -- Git integration with enhanced mappings
    require('gitsigns').setup({
      signs = {
        add = { text = '│' },
        change = { text = '│' },
        delete = { text = '_' },
        topdelete = { text = '‾' },
        changedelete = { text = '~' },
      },
      current_line_blame = false,
      on_attach = function(bufnr)
        local gs = package.loaded.gitsigns

        local function map(mode, l, r, opts)
          opts = opts or {}
          opts.buffer = bufnr
          vim.keymap.set(mode, l, r, opts)
        end

        -- Git hunk navigation and operations
        map('n', '<leader>gb', gs.toggle_current_line_blame, { desc = 'Toggle git blame' })
        map('n', '<leader>gp', gs.preview_hunk, { desc = 'Preview hunk' })
        map('n', '<leader>gr', gs.reset_hunk, { desc = 'Reset hunk' })
        map('n', '<leader>gs', gs.stage_hunk, { desc = 'Stage hunk' })
        map('n', '<leader>gu', gs.undo_stage_hunk, { desc = 'Undo stage hunk' })
        map('n', '[h', gs.prev_hunk, { desc = 'Previous hunk' })
        map('n', ']h', gs.next_hunk, { desc = 'Next hunk' })
      end
    })

    -- Colorscheme
    vim.cmd 'colorscheme nightfox'

    -- Agda configuration
    vim.g.cornelis_agda_prefix = "<C-g>"
    vim.api.nvim_create_autocmd({"BufRead", "BufNewFile"}, {
      pattern = "*.agda",
      callback = function()
        local agda_maps = {
          {"<leader>l", ":CornelisLoad<CR>", "Load Agda file"},
          {"<leader>r", ":CornelisRefine<CR>", "Refine goal"},
          {"<leader>,", ":CornelisTypeContext<CR>", "Type context"},
          {"gd", ":CornelisGoToDefinition<CR>", "Go to definition"},
          {"[/", ":CornelisPrevGoal<CR>", "Previous goal"},
          {"]/", ":CornelisNextGoal<CR>", "Next goal"},
        }

        local agda_mappings = {}
        for _, map in ipairs(agda_maps) do
          vim.keymap.set("n", map[1], map[2], { buffer = true, desc = map[3] })
          table.insert(agda_mappings, { map[1], desc = map[3], buffer = true })
        end

        wk.add(agda_mappings)
      end
    })

    -- Common Lisp configuration
    vim.g['conjure#client#common_lisp#swank#connection#default_port'] = "4005"
    vim.g['conjure#log#hud#enabled'] = false

    vim.api.nvim_create_autocmd("FileType", {
      pattern = {"lisp", "commonlisp"},
      callback = function()
        vim.opt_local.lisp = true
        local opts = { buffer = true, silent = true }

        -- Conjure mappings
        vim.keymap.set('n', '<localleader>ee', '<cmd>ConjureEval<cr>', vim.tbl_extend('force', opts, { desc = 'Eval form' }))
        vim.keymap.set('n', '<localleader>cf', '<cmd>ConjureConnect<cr>', vim.tbl_extend('force', opts, { desc = 'Connect SWANK' }))

        -- Register with which-key
        wk.add({
          { "<localleader>e", group = "Evaluate", buffer = true },
          { "<localleader>c", group = "Connect", buffer = true },
          { "<localleader>ee", desc = "Eval form", buffer = true },
          { "<localleader>cf", desc = "Connect SWANK", buffer = true },
        })
      end,
    })

    -- Helper commands
    vim.api.nvim_create_user_command('SwankStart', function()
      vim.fn.system('sbcl --eval "(asdf:load-system \'swank)" --eval "(swank:create-server :port 4005 :dont-close t)" &')
      print("SWANK server starting on port 4005...")
    end, { desc = 'Start SWANK server' })
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
