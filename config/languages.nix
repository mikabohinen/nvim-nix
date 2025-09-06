{ pkgs, lib }:
{
  /*
    Language Definition Schema:

    Each language in the input attrset should follow this structure:

    <language-name> = {
      # Optional: LSP server configuration
      lsp = {
        package = <derivation>;      # The LSP server package (e.g., pkgs.pyright)
        serverName = <string>;       # The lspconfig server name (e.g., "pyright")
        settings = <attrset>;        # Optional: LSP server settings (will be JSON-encoded)
        onInit = <string>;           # Optional: Lua function string for onInit callback
      };

      # Optional: Treesitter parser name
      treesitter = <string>;         # Parser name (e.g., "python", "nix")

      # Optional: Formatter configuration
      formatter = {
        package = <derivation>;      # The formatter package (e.g., pkgs.black)
        name = <string>;             # The formatter command name
      };
    };

    All fields are optional, languages can have any combination of LSP, treesitter, and formatter support.
  */
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
}
