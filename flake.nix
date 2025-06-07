{
  description = "A reproducible and minimal Neovim configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    neovim-nightly-overlay = {
      url = "github:nix-community/neovim-nightly-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, flake-utils, ... }@inputs:
    (flake-utils.lib.eachDefaultSystem
      (system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [ inputs.neovim-nightly-overlay.overlays.default ];
          };

          nvimPackages = pkgs.callPackage ./default.nix { inherit pkgs; };
          utils = import ./lib/utils.nix { inherit pkgs lib; };
          lib = nixpkgs.lib;

        in
        {
          packages = {
            default = nvimPackages.full;
            neovim = nvimPackages.neovim;
            neovim-full = nvimPackages.full;
            dev-tools = pkgs.buildEnv {
              name = "nvim-dev-tools";
              paths = nvimPackages.languageServers ++ nvimPackages.formatters ++ nvimPackages.extraTools;
            };
          };

          apps = utils.makeApps nvimPackages;

          devShells = {
            default = utils.makeDevShell nvimPackages;
            plugins = nvimPackages.pluginInfo.devShell;
          };

          lib.versionInfo = utils.getVersionInfo nvimPackages;
        }
      )) // {
      nixosModules.default = import ./modules/nixos.nix;
      homeManagerModules.default = import ./modules/home-manager.nix;

      overlays.default = final: prev: {
        nvim-nix = self.packages.${prev.system}.default;
      };
    };
}
