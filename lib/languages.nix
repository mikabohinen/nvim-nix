# lib/languages.nix
# Language support definitions

{ pkgs }:

{
  # Supported languages with their tooling
  # Each language can have: lsp, treesitter, formatter
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
      # Note: No LSP or formatter - we use structural editing instead
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
      lsp = {
        package = pkgs.lua-language-server;
        serverName = "lua_ls";
        settings = {
          Lua = {};
        };
        onInit = ''
          function(client)
            if client.workspace_folders then
              local path = client.workspace_folders[1].name
              if path ~= vim.fn.stdpath('config') and (vim.loop.fs_stat(path..'/.luarc.json') or vim.loop.fs_stat(path..'/.luarc.jsonc')) then
                return
              end
            end

            client.config.settings.Lua = vim.tbl_deep_extend('force', client.config.settings.Lua, {
              runtime = { version = 'LuaJIT' },
              workspace = {
                checkThirdParty = false,
                library = {
                  vim.env.VIMRUNTIME,
                  "''${3rd}/luv/library",
                  "''${3rd}/busted/library",
                }
              }
            })
          end
        '';
      };
      treesitter = "lua";
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

  # Extract components from language definitions
  extractComponents = languages: {
    languageServers = builtins.filter (x: x != null) (
      builtins.map
        (lang: if builtins.hasAttr "lsp" lang then lang.lsp.package else null)
        (builtins.attrValues languages)
    );

    treesitterParsers = builtins.filter (x: x != null) (
      builtins.map
        (lang: if builtins.hasAttr "treesitter" lang then lang.treesitter else null)
        (builtins.attrValues languages)
    );

    formatters = builtins.filter (x: x != null) (
      builtins.map
        (lang: if builtins.hasAttr "formatter" lang then lang.formatter.package else null)
        (builtins.attrValues languages)
    );
  };

  # Generate LSP setup code
  generateLspSetup = languages: builtins.concatStringsSep "\n" (
    builtins.map
      (name:
        let
          lang = languages.${name};
          hasLsp = builtins.hasAttr "lsp" lang;
          hasSettings = hasLsp && builtins.hasAttr "settings" lang.lsp;
          hasOnInit = hasLsp && builtins.hasAttr "onInit" lang.lsp;
          settingsJson = if hasSettings then builtins.toJSON lang.lsp.settings else "{}";
          onInitPart = if hasOnInit then "on_init = ${lang.lsp.onInit}," else "";
        in
        if hasLsp then
          "lspconfig.${lang.lsp.serverName}.setup({${onInitPart} settings = vim.fn.json_decode('${settingsJson}')})"
        else ""
      )
      (builtins.attrNames languages)
  );

  # Additional development tools
  extraTools = with pkgs; [
    # Core tools
    ripgrep
    fd
    git

    # Lisp development
    (pkgs.sbcl.withPackages (ps: with ps; [
      swank
      alexandria
      bordeaux-threads
    ]))
    rlwrap

    # Python tools
    python312Packages.flake8
    python312Packages.isort
    python312Packages.pyupgrade
  ];
}
