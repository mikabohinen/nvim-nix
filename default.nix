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
      formatter = {
        name = "latexindent";
        package = pkgs.texlive.combined.scheme-medium;
      };
    };
    lua = {
      formatter = {
        name = "stylua";
        package = pkgs.stylua;
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

    # Syntax/treesitter
    (nvim-treesitter.withPlugins (p:
      builtins.map (name: p.${name}) treesitterParsers
    ))

    # File navigation
    plenary-nvim
    telescope-nvim

    # Agda
    cornelis

    # Formatting
    conform-nvim

    # Requested extra plugins
    vim-sleuth
    unicode-vim

    # References
    papis-nvim
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
        }
      }
    })

    -- Manual formatting keybinding
    vim.keymap.set("n", "<leader>cf", function()
      conform.format({ async = true, lsp_fallback = true })
    end, { desc = "Format buffer" })

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

    -- Using Neovim's native completion (no nvim-cmp)

    -- papis.nvim setup
    require('papis').setup({
      -- Enable default keymaps for easier use
      enable_keymaps = true,

      -- Customize the filetypes that will activate papis.nvim
      init_filetypes = { "markdown", "tex", "norg", "yaml", "typst" },

      -- Enable icons for better visual experience
      enable_icons = true,

      -- Store database in a persistent location
      db_path = vim.fn.expand("~/.local/share/papis_db/papis-nvim.sqlite3"),

      -- Disable the completion module since we're not using nvim-cmp
      enable_modules = {
        ["search"] = true,
        ["completion"] = false,  -- Disable completion module that requires nvim-cmp
        ["at-cursor"] = true,
        ["formatter"] = true,
        ["colors"] = true,
        ["base"] = true,
        ["debug"] = true,  -- Enable debug module to help diagnose issues
      },

      -- Configuration for the formatter module (customize for markdown notes)
      ["formatter"] = {
        format_notes = function(entry)
          -- Format for the note title
          local title_format = {
            { "author", "%s ", "" },
            { "year", "(%s) ", "" },
            { "title", "%s", "" },
          }
          -- Format the strings with information in the entry
          local title = require("papis.utils"):format_display_strings(entry, title_format, true)
          -- Grab only the strings (and disregard highlight groups)
          for k, v in ipairs(title) do
            title[k] = v[1]
          end
          -- Define all the lines to be inserted
          local lines = {
            "---",
            'title: "Notes -- ' .. table.concat(title) .. '"',
            "date: " .. os.date("%Y-%m-%d"),
            "tags: [notes, reference]",
            "---",
            "",
            "# " .. table.concat(title),
            "",
            "## Summary",
            "",
            "## Key Points",
            "",
            "## Notes",
            "",
            "## References",
            "",
          }
          return lines
        end,

        -- Format for inserting references
        format_references = function(entry)
          local reference_format = {
            { "author",  "%s ",   "" },
            { "year",    "(%s). ", "" },
            { "title",   "%s. ",  "" },
            { "journal", "%s. ",    "" },
            { "volume",  "%s",    "" },
            { "number",  "(%s)",  "" },
          }
          local reference_data = require("papis.utils"):format_display_strings(entry, reference_format)
          for k, v in ipairs(reference_data) do
            reference_data[k] = v[1]
          end
          local lines = { table.concat(reference_data) }
          return lines
        end,
      },

      -- Custom keybindings (in addition to default ones)
      ["keymaps"] = {
        -- Search your bibliography
        vim.keymap.set('n', '<leader>ps', '<cmd>Papis search<CR>', { desc = "Papis search" }),
        -- Show citation info at cursor
        vim.keymap.set('n', '<leader>pi', '<cmd>Papis at-cursor show-popup<CR>', { desc = "Papis show info" }),
        -- Open file associated with citation at cursor
        vim.keymap.set('n', '<leader>pf', '<cmd>Papis at-cursor open-file<CR>', { desc = "Papis open file" }),
        -- Open note associated with citation at cursor
        vim.keymap.set('n', '<leader>pn', '<cmd>Papis at-cursor open-note<CR>', { desc = "Papis open note" }),
        -- Edit citation info
        vim.keymap.set('n', '<leader>pe', '<cmd>Papis at-cursor edit<CR>', { desc = "Papis edit entry" }),
      }
    })

    -- Load papis database on startup
    vim.api.nvim_create_autocmd("User", {
      pattern = "PapisStarted",
      callback = function()
        -- Check if database exists, if not prompt user to load it
        local Path = require("pathlib")
        local db_path = Path:new(vim.fn.expand("~/.local/share/papis_db/papis-nvim.sqlite3"))

        if not db_path:exists() then
          print("papis.nvim database not found. Please run :Papis reload data to initialize it.")
          print("If you're seeing errors about missing library directories, make sure they exist at ~/Documents/papers and ~/Documents/books")
        end
      end
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
    exec = "nvim %F";
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
  paths = [ neovimWrapped desktopItem ]; # Include the desktop item here
  buildInputs = [ pkgs.makeWrapper ];

  # Add required runtime dependencies
  postBuild = ''
    wrapProgram $out/bin/nvim \
      --prefix PATH : ${pkgs.lib.makeBinPath (
        languageServers ++ formatters ++ [
          pkgs.ripgrep
          pkgs.fd
          pkgs.yq-go     # Required for papis.nvim
          pkgs.sqlite    # Required for papis.nvim
          pkgs.papis     # The actual papis program
        ]
      )}
  '';
}
