{
  description = "A reproducible and principled Neovim configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    neovim-nightly-overlay = {
      url = "github:nix-community/neovim-nightly-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, flake-utils, ... }@inputs:
    let
      lib = nixpkgs.lib.extend (final: prev: (import ./lib {
	inherit final prev;
      }));
    in
    (flake-utils.lib.eachDefaultSystem
      (system:
        let
          pkgs = import nixpkgs {
            localSystem = { inherit system; };
            overlays = [ inputs.neovim-nightly-overlay.overlays.default ];
          };
        in
        {
          packages = {
            nvim-nix = pkgs.callPackage ./package { inherit lib; };
            default = self.packages.${system}.nvim-nix;
          };

          apps = {
	    nvim-nix = {
	      type = "app";
	      program = "${self.packages.${system}.nvim-nix}/bin/nvim";
	    };
	    default = self.apps.${system}.nvim-nix;
	  };
        }
      )) // {
      overlays.default = final: prev: {
        nvim-nix = self.packages.${prev.system}.default;
      };
    };
}
