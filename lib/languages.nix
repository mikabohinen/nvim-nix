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
        let lang = languages.${name}; in
        if builtins.hasAttr "lsp" lang then
          "lspconfig.${lang.lsp.serverName}.setup{}"
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
