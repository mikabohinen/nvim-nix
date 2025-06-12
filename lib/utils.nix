# lib/utils.nix
# Utility functions for nvim-nix

{ pkgs, lib }:

rec {
  makeApps = packages: {
    default = {
      type = "app";
      program = "${packages.full}/bin/nvim";
    };

    neovim = {
      type = "app";
      program = "${packages.neovim}/bin/nvim";
    };

    dev = {
      type = "app";
      program = toString (pkgs.writeShellScript "nvim-dev" ''
        export PATH="${lib.makeBinPath (packages.languageServers ++ packages.formatters ++ packages.extraTools)}:$PATH"
        exec ${packages.full}/bin/nvim "$@"
      '');
    };
  };

  makeDevShell = packages: pkgs.mkShell {
    buildInputs = with pkgs; [
      packages.full
    ] ++ packages.languageServers ++ packages.formatters ++ packages.extraTools ++ [
      # Additional development tools
      git
      curl
      wget
      tree
      fd
      ripgrep
      fzf
    ];

    shellHook = ''
      echo "🚀 Neovim development environment loaded!"
      echo "📝 Editor: nvim"
      echo "🔧 Formatters: ${lib.concatMapStringsSep ", " (p: p.pname or p.name) packages.formatters}"
      echo "🔍 LSP servers: ${lib.concatMapStringsSep ", " (p: p.pname or p.name) packages.languageServers}"
      echo ""
    '';
  };

  # Version information for debugging
  getVersionInfo = packages: {
    nvim-nix-version = "1.0.0";
    plugin-count = 8;
    local-plugins = [
      "vim-surround"
      "vim-vinegar"
      "vim-repeat"
      "vim-fugitive"
      "vim-sexp"
    ];
    nixpkgs-plugins = [
      "nvim-lspconfig"
      "nvim-treesitter"
      "nvim-treesitter-textobjects"
    ];
    language-servers = map (p: p.pname or p.name) packages.languageServers;
    formatters = map (p: p.pname or p.name) packages.formatters;
  };
}
