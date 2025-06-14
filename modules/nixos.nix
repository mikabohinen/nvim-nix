# modules/nixos.nix
# NixOS system module for nvim-nix

{ nixpkgs, overlay }: { config, lib, pkgs, ... }:

with lib;
let
  cfg = config.programs.nvimNix;

  nvimPkgs = import nixpkgs {
    inherit (pkgs) system;
    overlays = [ overlay ];
  };

  nvimPackages = nvimPkgs.callPackage ../default.nix { pkgs = nvimPkgs; };
  inherit (nvimPackages) languageServers formatters extraTools;

  desktop = import ../lib/desktop.nix { pkgs = nvimPkgs; inherit lib; };
in
{
  options.programs.nvimNix = {
    enable = mkEnableOption "Enable minimal neovim distribution";

    package = mkOption {
      type = types.package;
      default = nvimPackages.full;
      defaultText = "nvim-nix full package with nightly neovim";
      description = "The neovim package to use";
    };

    defaultEditor = mkOption {
      type = types.bool;
      default = true;
      description = "Set nvim as the default system editor";
    };

    enableDevTools = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to install development tools system-wide";
    };

    enableGitIntegration = mkOption {
      type = types.bool;
      default = true;
      description = "Configure git to use nvim as editor";
    };

    shellAliases = mkOption {
      type = types.attrsOf types.str;
      default = {
        vi = "nvim";
        vim = "nvim";
      };
      description = "Shell aliases to add system-wide";
    };

    enableDesktopEntry = mkOption {
      type = types.bool;
      default = config.services.xserver.enable || config.services.displayManager.enable;
      description = "Create desktop entry for GUI environments";
    };

    terminalEmulator = mkOption {
      type = types.enum ([ "auto" ] ++ builtins.attrNames desktop.terminalEmulators);
      default = "auto";
      description = ''
        Terminal emulator to use for desktop entries.
        "auto" will detect based on desktop environment.
        Available options: ${concatStringsSep ", " (["auto"] ++ builtins.attrNames desktop.terminalEmulators)}
      '';
    };

    installTerminalEmulator = mkOption {
      type = types.bool;
      default = cfg.enableDesktopEntry && cfg.terminalEmulator != "auto";
      description = "Whether to install the selected terminal emulator system-wide";
    };

    createGuiWrapper = mkOption {
      type = types.bool;
      default = cfg.enableDesktopEntry;
      description = "Create nvim-gui command for launching nvim in a terminal from GUI";
    };
  };

  config = mkIf cfg.enable (
    let
      basePackages = [ cfg.package ] ++
        optionals cfg.enableDevTools (languageServers ++ formatters ++ extraTools);

      terminalPackage =
        if cfg.installTerminalEmulator && cfg.terminalEmulator != "auto"
        then [ (desktop.getTerminalPackage cfg.terminalEmulator) ]
        else [ ];

      guiWrapper = optional cfg.createGuiWrapper
        (desktop.makeTerminalWrapper {
          terminalEmulator = cfg.terminalEmulator;
          nvimPackage = cfg.package;
        });

      desktopTerminal =
        if cfg.terminalEmulator != "auto"
        then cfg.terminalEmulator
        else if config.services.xserver.desktopManager.gnome.enable
        then "gnome-terminal"
        else if config.services.xserver.desktopManager.plasma5.enable ||
          config.services.xserver.desktopManager.plasma6.enable
        then "konsole"
        else "auto";

      desktopEntries =
        if cfg.enableDesktopEntry
        then
          desktop.makeDesktopEntries
            {
              terminalEmulator = desktopTerminal;
              availablePackages = config.environment.systemPackages;
              nvimPackage = cfg.package;
              createVariants = true;
            }
        else { };
    in
    {
      environment.systemPackages = basePackages ++ terminalPackage ++ guiWrapper;

      environment.variables = mkIf cfg.defaultEditor {
        EDITOR = "nvim";
        VISUAL = "nvim";
      };

      environment.shellAliases = cfg.shellAliases;

      environment.etc = mkMerge [
        # Git configuration
        (mkIf (cfg.defaultEditor && cfg.enableGitIntegration) {
          "gitconfig" = {
            text = ''
              [core]
                editor = nvim
              [merge]
                tool = nvim
              [mergetool "nvim"]
                cmd = nvim -d $LOCAL $REMOTE $MERGED -c '$wincmd w' -c 'wincmd J'
              [diff]
                tool = nvim
              [difftool "nvim"]
                cmd = nvim -d $LOCAL $REMOTE
            '';
          };
        })

        # Desktop entries
        (mkIf cfg.enableDesktopEntry (
          mapAttrs'
            (name: entry: {
              name = "xdg/applications/nvim-${name}.desktop";
              value.text = generators.toINI { }
                {
                  "Desktop Entry" = {
                    Type = "Application";
                    Name = entry.desktopName;
                    GenericName = entry.genericName or "";
                    Comment = entry.comment or "";
                    Exec = entry.exec;
                    Icon = entry.icon or "";
                    Terminal = entry.terminal or false;
                    Categories = concatStringsSep ";" (entry.categories or [ ]);
                    MimeType = concatStringsSep ";" (entry.mimeType or [ ]);
                    Keywords = concatStringsSep ";" (entry.keywords or [ ]);
                    StartupNotify = entry.startupNotify or false;
                    NoDisplay = entry.noDisplay or false;
                  };
                } // (mapAttrs
                (actionName: actionConfig: {
                  "Desktop Action ${actionName}" = {
                    Name = actionConfig.name;
                    Exec = actionConfig.exec;
                  };
                })
                (entry.actions or { }));
            })
            desktopEntries
        ))
      ];
    }
  );
}
