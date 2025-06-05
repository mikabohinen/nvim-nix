{ pkgs, ... }:

let
  # Build custom plugins from source
  customPlugins = { };

  vimrcConfig = pkgs.writeText "vimrc" (builtins.readFile ./vimrc.vim);

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

  # Plugins list
  plugins = with pkgs.vimPlugins; [
    # LSP
    nvim-lspconfig

    # Autopairs
    nvim-autopairs

    # Syntax/treesitter with enhanced highlighting
    (nvim-treesitter.withPlugins (p:
      builtins.map (name: p.${name}) treesitterParsers
    ))
    nvim-treesitter-textobjects # Better text objects
    rainbow-delimiters-nvim # Rainbow parentheses

    # File navigation
    plenary-nvim
    telescope-nvim
    oil-nvim

    # Git integration
    gitsigns-nvim
    vim-fugitive

    # UI improvements
    lualine-nvim

    # Essential editing
    comment-nvim
    undotree

    # Agda
    cornelis

    # Which-key for keybinding discovery
    which-key-nvim

    # Common Lisp REPL Integration
    conjure
    vim-sexp
    vim-sexp-mappings-for-regular-people

    # Enhanced syntax highlighting
    nvim-colorizer-lua
    indent-blankline-nvim

    # Formatting
    conform-nvim

    # Colorscheme
    nightfox-nvim

    # Utility plugins
    vim-sleuth
    unicode-vim
    vim-surround
  ];

  # Neovim configuration
  neovimConfig = pkgs.writeText "init.lua" ''
    vim.cmd.source('${vimrcConfig}')

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

    -- Which-key setup (setup early so other plugins can use it)
    local wk = require("which-key")
    wk.setup({
      preset = "modern",
      delay = 300,
      expand = 1, -- expand groups when <= n mappings
      notify = true,
      win = {
        border = "rounded",
        padding = { 1, 2 },
      },
      layout = {
        spacing = 3,
      },
    })

    -- Additional keybindings for new features
    -- Oil file explorer
    vim.keymap.set('n', '<leader>fe', '<cmd>Oil<cr>', { desc = "Open file explorer" })
    vim.keymap.set('n', '-', '<cmd>Oil<cr>', { desc = "Open parent directory" })

    -- Git operations (gitsigns)
    vim.keymap.set('n', '<leader>gb', '<cmd>Gitsigns toggle_current_line_blame<cr>', { desc = "Toggle git blame" })
    vim.keymap.set('n', '<leader>gp', '<cmd>Gitsigns preview_hunk<cr>', { desc = "Preview hunk" })
    vim.keymap.set('n', '<leader>gr', '<cmd>Gitsigns reset_hunk<cr>', { desc = "Reset hunk" })
    vim.keymap.set('n', '<leader>gs', '<cmd>Gitsigns stage_hunk<cr>', { desc = "Stage hunk" })
    vim.keymap.set('n', '<leader>gu', '<cmd>Gitsigns undo_stage_hunk<cr>', { desc = "Undo stage hunk" })
    vim.keymap.set('n', '<leader>gd', '<cmd>Gitsigns diffthis<cr>', { desc = "Diff this" })
    vim.keymap.set('n', '[h', '<cmd>Gitsigns prev_hunk<cr>', { desc = "Previous hunk" })
    vim.keymap.set('n', ']h', '<cmd>Gitsigns next_hunk<cr>', { desc = "Next hunk" })

    -- Git operations (fugitive)
    vim.keymap.set('n', '<leader>gg', '<cmd>Git<cr>', { desc = "Git status" })
    vim.keymap.set('n', '<leader>gc', '<cmd>Git commit<cr>', { desc = "Git commit" })
    vim.keymap.set('n', '<leader>gP', '<cmd>Git push<cr>', { desc = "Git push" })
    vim.keymap.set('n', '<leader>gl', '<cmd>Git pull<cr>', { desc = "Git pull" })
    vim.keymap.set('n', '<leader>gB', '<cmd>Git blame<cr>', { desc = "Git blame (fugitive)" })
    vim.keymap.set('n', '<leader>gD', '<cmd>Gdiffsplit<cr>', { desc = "Git diff split" })
    vim.keymap.set('n', '<leader>gw', '<cmd>Gwrite<cr>', { desc = "Git write (stage file)" })
    vim.keymap.set('n', '<leader>gR', '<cmd>Gread<cr>', { desc = "Git read (checkout file)" })

    -- Undotree
    vim.keymap.set('n', '<leader>ut', vim.cmd.UndotreeToggle, { desc = "Toggle undotree" })

    -- Enhanced syntax highlighting setup
    -- Treesitter configuration
    require('nvim-treesitter.configs').setup({
      ensure_installed = {}, -- We manage parsers through Nix
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

    -- Color highlighting for hex codes, rgb(), etc.
    require('colorizer').setup({
      filetypes = {
        "*", -- Enable for all files
        css = { rgb_fn = true }, -- Enable parsing rgb(...) functions in css
        html = { names = false }, -- Disable parsing "names" like Blue or Gray
      },
      user_default_options = {
        RGB = true,      -- #RGB hex codes
        RRGGBB = true,   -- #RRGGBB hex codes
        names = true,    -- "Name" codes like Blue or blue
        RRGGBBAA = true, -- #RRGGBBAA hex codes
        rgb_fn = true,   -- CSS rgb() and rgba() functions
        hsl_fn = true,   -- CSS hsl() and hsla() functions
        css = true,      -- Enable all CSS features
        css_fn = true,   -- Enable all CSS *functions*
        mode = "background", -- Set the display mode
      },
    })

    -- Indentation guides
    require('ibl').setup({
      indent = {
        char = "│",
        tab_char = "│",
      },
      scope = {
        enabled = true,
        show_start = true,
        show_end = true,
        highlight = { "Function", "Label" },
      },
      exclude = {
        filetypes = {
          "help",
          "alpha",
          "dashboard",
          "neo-tree",
          "Trouble",
          "lazy",
          "mason",
          "notify",
          "toggleterm",
          "lazyterm",
        },
      },
    })

    -- LSP setup
    local lspconfig = require('lspconfig')

    -- Set up language servers (dynamically generated)
    ${lspSetupCode}

    -- LSP diagnostic keybindings
    vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, { desc = "Show diagnostic at cursor" })
    vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, { desc = "Go to previous diagnostic" })
    vim.keymap.set('n', ']d', vim.diagnostic.goto_next, { desc = "Go to next diagnostic" })
    vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = "Show diagnostics in location list" })

    -- Formatting setup with conform.nvim
    local conform = require("conform")

    -- Initialize formatter configuration
    local formatters_by_ft = {
      ["*"] = { "trim_whitespace" }
    }

    -- Add our language-specific formatters
    ${builtins.concatStringsSep "\n    " (
      builtins.map
        (name: let lang = supportedLanguages.${name}; in
          if builtins.hasAttr "formatter" lang then
            ''formatters_by_ft["${name}"] = { "${lang.formatter.name}" }''
          else ""
        )
        (builtins.attrNames supportedLanguages)
    )}

    -- Configure the plugin
    conform.setup({
      formatters_by_ft = formatters_by_ft,
      format_on_save = {
        timeout_ms = 500,
        lsp_fallback = true,
      },
      formatters = {
        shfmt = {
          args = { "-i", "2", "-ci" },
        },
        stylua = {
          args = {
            "--indent-type", "Spaces",
            "--indent-width", "2",
            "--quote-style", "AutoPreferDouble",
          },
        },
        black = {
          args = {
            "--line-length", "100",
          },
        }
      }
    })

    -- Manual formatting keybinding
    vim.keymap.set("n", "<leader>cf", function()
      conform.format({ async = true, lsp_fallback = true })
    end, { desc = "Format buffer" })

    -- Auto-pairs setup with Lisp-friendly configuration
    require('nvim-autopairs').setup({
      disable_filetype = { "TelescopePrompt", "vim" },
      disable_in_macro = false,
      disable_in_visualblock = false,
      disable_in_replace_mode = true,
      ignored_next_char = [=[[%w%%%'%[%"%.%`%$]]=],
      enable_moveright = true,
      enable_afterquote = true,
      enable_check_bracket_line = false,
      enable_bracket_in_quote = true,
      enable_abbr = false,
      break_undo = true,
      check_ts = false,
      map_bs = true,
      map_c_h = false,
      map_c_w = false,
    })

    -- Configure autopairs for better Lisp experience
    local npairs = require('nvim-autopairs')

    -- Disable smart bracket checking in Lisp files
    vim.api.nvim_create_autocmd("FileType", {
      pattern = {"lisp", "commonlisp", "scheme", "clojure"},
      callback = function()
        -- Simple rule: always insert () when typing ( in Lisp files
        vim.keymap.set('i', '(', '()<Left>', { buffer = true, desc = 'Insert () pair' })
      end,
    })

    -- Telescope setup
    require('telescope').setup{}
    vim.keymap.set('n', '<leader>ff', require('telescope.builtin').find_files, { desc = "Find files" })
    vim.keymap.set('n', '<leader><leader>', require('telescope.builtin').find_files, { desc = "Find files" })
    vim.keymap.set('n', '<leader>fw', require('telescope.builtin').live_grep, { desc = "Live grep" })
    vim.keymap.set('n', '<leader>fb', require('telescope.builtin').buffers, { desc = "Find buffers" })

    -- Git integration with gitsigns
    require('gitsigns').setup({
      signs = {
        add          = { text = '│' },
        change       = { text = '│' },
        delete       = { text = '_' },
        topdelete    = { text = '‾' },
        changedelete = { text = '~' },
        untracked    = { text = '┆' },
      },
      current_line_blame = false,
      current_line_blame_opts = {
        virt_text = true,
        virt_text_pos = 'eol',
        delay = 1000,
      },
    })

    -- Simple statusline
    require('lualine').setup({
      options = {
        theme = 'auto',
        component_separators = { left = ''', right = ''' },
        section_separators = { left = ''', right = ''' },
      },
      sections = {
        lualine_a = {'mode'},
        lualine_b = {'branch', 'diff', 'diagnostics'},
        lualine_c = {'filename'},
        lualine_x = {'encoding', 'fileformat', 'filetype'},
        lualine_y = {'progress'},
        lualine_z = {'location'}
      },
    })

    -- Oil.nvim - edit directories like buffers
    require('oil').setup({
      default_file_explorer = true,
      delete_to_trash = true,
      skip_confirm_for_simple_edits = true,
      view_options = {
        show_hidden = false,
        natural_order = true,
      },
      float = {
        padding = 2,
        max_width = 90,
        max_height = 0,
      },
      keymaps = {
        ["g?"] = "actions.show_help",
        ["<CR>"] = "actions.select",
        ["<C-v>"] = "actions.select_vsplit",
        ["<C-x>"] = "actions.select_split",
        ["<C-t>"] = "actions.select_tab",
        ["<C-p>"] = "actions.preview",
        ["<C-c>"] = "actions.close",
        ["q"] = "actions.close",
        ["-"] = "actions.parent",
        ["_"] = "actions.open_cwd",
        ["`"] = "actions.cd",
        ["~"] = "actions.tcd",
        ["gs"] = "actions.change_sort",
        ["gx"] = "actions.open_external",
        ["g."] = "actions.toggle_hidden",
      },
    })

    -- Comment toggling
    require('Comment').setup({
      padding = true,
      sticky = true,
      toggler = {
        line = 'gcc',
        block = 'gbc',
      },
      opleader = {
        line = 'gc',
        block = 'gb',
      },
      extra = {
        above = 'gcO',
        below = 'gco',
        eol = 'gcA',
      },
    })

    -- Register which-key groups and mappings
    wk.add({
      -- Leader key groups
      { "<leader>f", group = "Find (Telescope)" },
      { "<leader>c", group = "Code" },
      { "<leader>g", group = "Git" },
      { "<leader>u", group = "UI/Utils" },

      -- File operations
      { "<leader>ff", desc = "Find files" },
      { "<leader>fw", desc = "Find words (live grep)" },
      { "<leader>fb", desc = "Find buffers" },
      { "<leader>fe", desc = "File explorer (Oil)" },

      -- Code operations
      { "<leader>cf", desc = "Format buffer" },
      { "<leader>e", desc = "Show diagnostics" },
      { "<leader>q", desc = "Diagnostic quickfix" },

      -- Git operations
      { "<leader>gb", desc = "Toggle git blame" },
      { "<leader>gp", desc = "Preview hunk" },
      { "<leader>gr", desc = "Reset hunk" },
      { "<leader>gs", desc = "Stage hunk" },
      { "<leader>gu", desc = "Undo stage hunk" },
      { "<leader>gd", desc = "Diff this" },

      -- UI/Utilities
      { "<leader>ut", desc = "Toggle undotree" },

      -- Diagnostics
      { "[d", desc = "Previous diagnostic" },
      { "]d", desc = "Next diagnostic" },
      { "[h", desc = "Previous git hunk" },
      { "]h", desc = "Next git hunk" },

      -- vim-surround operations
      { "cs", desc = "Change surrounding" },
      { "ds", desc = "Delete surrounding" },
      { "ys", desc = "Add surrounding" },
      { mode = "v", { "S", desc = "Surround selection" } },

      -- Comment operations
      { "gcc", desc = "Toggle line comment" },
      { "gbc", desc = "Toggle block comment" },
      { mode = "v", { "gc", desc = "Toggle comment" } },
      { mode = "v", { "gb", desc = "Toggle block comment" } },

      -- Treesitter navigation
      { "]f", desc = "Next function" },
      { "[f", desc = "Previous function" },
      { "]c", desc = "Next class" },
      { "[c", desc = "Previous class" },
      { "]F", desc = "Next function end" },
      { "[F", desc = "Previous function end" },

      -- Treesitter selection
      { "gnn", desc = "Init selection" },
      { "grn", desc = "Increment selection" },
      { "grc", desc = "Increment scope" },
      { "grm", desc = "Decrement selection" },
    })

    -- Using a colorscheme that works well with enhanced syntax highlighting
    vim.cmd 'colorscheme nightfox'

    vim.g.cornelis_agda_prefix = "<C-g>"

    -- Set up autocommands for Agda files
    vim.api.nvim_create_autocmd({"BufRead", "BufNewFile"}, {
        pattern = "*.agda",
        callback = function()
            -- Key mappings for Agda files
            local agda_keymaps = {
                {"<leader>l", ":CornelisLoad<CR>", "Load Agda file"},
                {"<leader>r", ":CornelisRefine<CR>", "Refine goal"},
                {"<leader>d", ":CornelisMakeCase<CR>", "Make case"},
                {"<leader>,", ":CornelisTypeContext<CR>", "Type context"},
                {"<leader>.", ":CornelisTypeContextInfer<CR>", "Type context infer"},
                {"<leader>n", ":CornelisSolve<CR>", "Solve goal"},
                {"<leader>a", ":CornelisAuto<CR>", "Auto solve"},
                {"<leader>m", ":CornelisMakeCase<CR>", "Make case"},
                {"gd",        ":CornelisGoToDefinition<CR>", "Go to definition"},
                {"[/",        ":CornelisPrevGoal<CR>", "Previous goal"},
                {"]/",        ":CornelisNextGoal<CR>", "Next goal"},
                {"<C-A>",     ":CornelisInc<CR>", "Increment"},
                {"<C-X>",     ":CornelisDec<CR>", "Decrement"}
            }

            -- Apply each keymap and register with which-key
            local agda_mappings = {}
            for _, map in ipairs(agda_keymaps) do
                vim.keymap.set("n", map[1], map[2], { buffer = true, desc = map[3] })
                table.insert(agda_mappings, { map[1], desc = map[3], buffer = true })
            end

            -- Register Agda specific which-key mappings
            wk.add(agda_mappings)

            vim.fn['cornelis#bind_input']("nat", "ℕ")
        end
    })

    -- Set up autocommand for closing info windows when quitting
    vim.api.nvim_create_autocmd("QuitPre", {
        pattern = "*.agda",
        command = "CornelisCloseInfoWindows"
    })

    -- Common Lisp SWANK/Conjure configuration
    -- Using Nixpkgs Common Lisp infrastructure with pre-built SWANK
    vim.g['conjure#client#common_lisp#swank#connection#default_host'] = "127.0.0.1"
    vim.g['conjure#client#common_lisp#swank#connection#default_port'] = "4005"
    vim.g['conjure#log#hud#enabled'] = false
    vim.g['conjure#log#hud#passive_close_delay'] = 0
    vim.g['conjure#client#common_lisp#swank#eval#result_comment_prefix'] = "; => "

    -- Common Lisp file type configuration
    vim.api.nvim_create_autocmd("FileType", {
      pattern = {"lisp", "commonlisp"},
      callback = function()
        vim.opt_local.lisp = true
        vim.opt_local.showmatch = true
        vim.opt_local.matchtime = 3

        -- Enhanced syntax options for Lisp
        vim.opt_local.syntax = "lisp"
        vim.opt_local.conceallevel = 0  -- Don't hide any characters
        vim.opt_local.cursorline = true -- Highlight current line

        -- Better folding for Lisp
        vim.opt_local.foldmethod = "expr"
        vim.opt_local.foldexpr = "nvim_treesitter#foldexpr()"
        vim.opt_local.foldenable = false -- Start with folds open

        -- Enhanced lispwords for better indentation
        vim.opt_local.lispwords:append({
          "defpackage", "in-package", "defclass", "defgeneric",
          "defmethod", "defmacro", "defun", "defvar", "defparameter",
          "defconstant", "defstruct", "deftype", "define-condition",
          "let*", "lambda", "case", "ccase", "ecase", "typecase",
          "etypecase", "ctypecase", "when", "unless", "cond",
          "loop", "do", "do*", "dotimes", "dolist", "with-slots",
          "with-accessors", "handler-case", "handler-bind",
          "restart-case", "restart-bind", "unwind-protect",
          "multiple-value-bind", "destructuring-bind"
        })

        -- Common Lisp specific keybindings
        local opts = { buffer = true, silent = true }

        -- Conjure REPL keybindings
        vim.keymap.set('n', '<localleader>ee', '<cmd>ConjureEval<cr>',
          vim.tbl_extend('force', opts, { desc = 'Evaluate form under cursor' }))
        vim.keymap.set('n', '<localleader>er', '<cmd>ConjureEvalRoot<cr>',
          vim.tbl_extend('force', opts, { desc = 'Evaluate root form' }))
        vim.keymap.set('n', '<localleader>ef', '<cmd>ConjureEvalFile<cr>',
          vim.tbl_extend('force', opts, { desc = 'Evaluate file' }))
        vim.keymap.set('n', '<localleader>eb', '<cmd>ConjureEvalBuf<cr>',
          vim.tbl_extend('force', opts, { desc = 'Evaluate buffer' }))
        vim.keymap.set('n', '<localleader>ls', '<cmd>ConjureLogSplit<cr>',
          vim.tbl_extend('force', opts, { desc = 'Open log in split' }))
        vim.keymap.set('n', '<localleader>lv', '<cmd>ConjureLogVSplit<cr>',
          vim.tbl_extend('force', opts, { desc = 'Open log in vsplit' }))
        vim.keymap.set('n', '<localleader>lt', '<cmd>ConjureLogTab<cr>',
          vim.tbl_extend('force', opts, { desc = 'Open log in tab' }))

        -- Connect to SWANK
        vim.keymap.set('n', '<localleader>cf', '<cmd>ConjureConnect<cr>',
          vim.tbl_extend('force', opts, { desc = 'Connect to SWANK' }))

        -- Documentation lookup
        vim.keymap.set('n', 'K', '<cmd>ConjureDocWord<cr>',
          vim.tbl_extend('force', opts, { desc = 'Show documentation' }))

        -- Register Common Lisp specific which-key mappings
        wk.add({
          { "<localleader>e", group = "Evaluate", buffer = true },
          { "<localleader>l", group = "Log", buffer = true },
          { "<localleader>c", group = "Connect", buffer = true },
          { "<localleader>w", group = "Wrap", buffer = true },

          -- Evaluation
          { "<localleader>ee", desc = "Eval form at cursor", buffer = true },
          { "<localleader>er", desc = "Eval root form", buffer = true },
          { "<localleader>ef", desc = "Eval file", buffer = true },
          { "<localleader>eb", desc = "Eval buffer", buffer = true },

          -- Log windows
          { "<localleader>ls", desc = "Log split", buffer = true },
          { "<localleader>lv", desc = "Log vsplit", buffer = true },
          { "<localleader>lt", desc = "Log tab", buffer = true },

          -- Connection
          { "<localleader>cf", desc = "Connect to SWANK", buffer = true },

          -- Documentation
          { "K", desc = "Show documentation", buffer = true },

          -- vim-sexp movement
          { "(", desc = "Move to previous form", buffer = true },
          { ")", desc = "Move to next form", buffer = true },
          { "[[", desc = "Move to previous top-level form", buffer = true },
          { "]]", desc = "Move to next top-level form", buffer = true },
          { "[e", desc = "Move to previous element", buffer = true },
          { "]e", desc = "Move to next element", buffer = true },

          -- vim-sexp slurping and barfing
          { ">)", desc = "Slurp forward", buffer = true },
          { "<)", desc = "Barf forward", buffer = true },
          { ">}", desc = "Slurp backward", buffer = true },
          { "<}", desc = "Barf backward", buffer = true },

          -- vim-sexp wrapping (localleader + w + character)
          { "<localleader>w(", desc = "Wrap with ()", buffer = true },
          { "<localleader>w[", desc = "Wrap with []", buffer = true },
          { "<localleader>w{", desc = "Wrap with {}", buffer = true },
          { "<localleader>w\"", desc = "Wrap with quotes", buffer = true },

          -- vim-sexp structural editing
          { "dsf", desc = "Delete surrounding form", buffer = true },
          { "<localleader>S", desc = "Splice form", buffer = true },
          { "<localleader>r", desc = "Raise form", buffer = true },
          { "<localleader>O", desc = "Raise element", buffer = true },

          -- vim-sexp insertion
          { "<localleader>h", desc = "Insert at head", buffer = true },
          { "<localleader>t", desc = "Insert at tail", buffer = true },

          -- Visual mode selections
          { mode = "v", { "af", desc = "Select outer form", buffer = true } },
          { mode = "v", { "if", desc = "Select inner form", buffer = true } },
          { mode = "v", { "ae", desc = "Select outer element", buffer = true } },
          { mode = "v", { "ie", desc = "Select inner element", buffer = true } },
          { mode = "v", { "<localleader>w", desc = "Wrap selection", buffer = true } },
        })
      end,
    })

    -- Helper commands for SWANK
    vim.api.nvim_create_user_command('SwankStart', function()
      local cmd = [[sbcl --eval "(load (sb-ext:posix-getenv \"ASDF\"))" --eval "(asdf:load-system 'swank)" --eval "(swank:create-server :port 4005 :dont-close t)" &]]
      vim.fn.system(cmd)
      print("SWANK server starting on port 4005...")
      print("Once started, use <localleader>cf to connect")
    end, { desc = 'Start SWANK server' })

    vim.api.nvim_create_user_command('SwankConnect', function()
      vim.cmd('ConjureConnect 127.0.0.1 4005')
    end, { desc = 'Connect to SWANK server' })

    -- Available Common Lisp packages (pre-installed via Nixpkgs):
    -- swank, alexandria, bordeaux-threads, quicklisp
    -- To use them in SBCL: (asdf:load-system 'package-name)
    -- To add more packages, edit sbclWithPackages in default.nix

    -- Additional which-key mappings for LSP (when available)
    vim.api.nvim_create_autocmd('LspAttach', {
      callback = function(event)
        local opts = { buffer = event.buf }

        -- LSP keybindings
        vim.keymap.set('n', 'gd', vim.lsp.buf.definition, vim.tbl_extend('force', opts, { desc = 'Go to definition' }))
        vim.keymap.set('n', 'gr', vim.lsp.buf.references, vim.tbl_extend('force', opts, { desc = 'Show references' }))
        vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, vim.tbl_extend('force', opts, { desc = 'Go to implementation' }))
        vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, vim.tbl_extend('force', opts, { desc = 'Rename symbol' }))
        vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, vim.tbl_extend('force', opts, { desc = 'Code actions' }))
        vim.keymap.set('n', 'K', vim.lsp.buf.hover, vim.tbl_extend('force', opts, { desc = 'Hover documentation' }))

        -- Register LSP which-key mappings
        wk.add({
          { "gd", desc = "Go to definition", buffer = event.buf },
          { "gr", desc = "Show references", buffer = event.buf },
          { "gi", desc = "Go to implementation", buffer = event.buf },
          { "<leader>r", group = "Refactor", buffer = event.buf },
          { "<leader>rn", desc = "Rename symbol", buffer = event.buf },
          { "<leader>ca", desc = "Code actions", buffer = event.buf },
          { "K", desc = "Hover documentation", buffer = event.buf },
        })
      end,
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

  # Add required runtime dependencies
  postBuild = ''
    wrapProgram $out/bin/nvim \
      --prefix PATH : ${pkgs.lib.makeBinPath (
        languageServers ++ formatters ++ [
          pkgs.ripgrep
          pkgs.fd
          pkgs.kitty
          pkgs.git
          # Common Lisp development tools
          sbclWithPackages
          pkgs.rlwrap
          # Python tools for pre-commit compatibility
          pkgs.python312Packages.flake8
          pkgs.python312Packages.isort
          pkgs.python312Packages.pyupgrade
        ]
      )}
  '';
}
