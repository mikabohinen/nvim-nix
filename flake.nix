{
  description = "My custom Neovim distribution";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    
    # Neovim nightly for latest features
    neovim-nightly-overlay = {
      url = "github:nix-community/neovim-nightly-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, flake-utils, ... }@inputs:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [
            inputs.neovim-nightly-overlay.overlays.default
          ];
        };
        
        # Import your neovim configuration
        myNeovim = pkgs.callPackage ./default.nix { 
          inherit pkgs;
        };
        
        # Simple NixOS module for easy integration
        nixosModule = { config, lib, pkgs, ... }: 
          with lib;
          let cfg = config.programs.mynvim;
          in {
            options.programs.mynvim = {
              enable = mkEnableOption "Enable my custom neovim distribution";
            };
            
            config = mkIf cfg.enable {
              environment.systemPackages = [ myNeovim ];
              environment.variables.EDITOR = "nvim";
            };
          };
      in
      {
        packages = {
          default = myNeovim;
          neovim = myNeovim;
        };
        
        # For development/testing
        apps.default = {
          type = "app";
          program = "${myNeovim}/bin/nvim";
        };
        
        # Make the NixOS module available
        nixosModules.default = nixosModule;
      }
    );
}
