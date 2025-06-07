# modules/home-manager.nix
# Home Manager module for nvim-nix

{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.programs.nvimNix;

  nvimPackages = pkgs.callPackage ../default.nix { inherit pkgs; };
  inherit (nvimPackages) languageServers formatters extraTools;

  desktop = import ../lib/desktop.nix { inherit pkgs lib; };
in {
  options.programs.nvimNix = {
    enable = mkEnableOption "Enable minimal neovim distribution";

    package = mkOption {
      type = types.package;
      default = nvimPackages.full;
      defaultText = "nvim-nix full package";
      description = "The neovim package to use";
    };

    enableDevTools = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to install development tools (formatters, linters, etc.)";
    };

    extraConfig = mkOption {
      type = types.lines;
      default = "";
      description = "Extra configuration to add to init.lua";
    };

    shellAliases = mkOption {
      type = types.attrsOf types.str;
      default = {
        vi = "nvim";
        vim = "nvim";
      };
      description = "Shell aliases for nvim";
    };

    setDefaultEditor = mkOption {
      type = types.bool;
      default = true;
      description = "Set nvim as the default EDITOR and VISUAL";
    };

    enableDesktopEntry = mkOption {
      type = types.bool;
      default = pkgs.stdenv.isLinux;
      description = "Create desktop entry for GUI environments";
    };

    terminalEmulator = mkOption {
      type = types.enum (["auto"] ++ builtins.attrNames desktop.terminalEmulators);
      default = "auto";
      description = ''
        Terminal emulator to use for desktop entries.
        "auto" will detect the best available terminal.
        Available options: ${concatStringsSep ", " (["auto"] ++ builtins.attrNames desktop.terminalEmulators)}
      '';
    };

    installTerminalEmulator = mkOption {
      type = types.bool;
      default = cfg.terminalEmulator != "auto";
      description = "Whether to install the selected terminal emulator";
    };

    createGuiWrapper = mkOption {
      type = types.bool;
      default = true;
      description = "Create nvim-gui command for launching nvim in a terminal from GUI";
    };

    extraMimeTypes = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "Additional MIME types to associate with nvim";
    };
  };

  config = mkIf cfg.enable (
    let
      basePackages = [ cfg.package ] ++
        optionals cfg.enableDevTools (languageServers ++ formatters ++ extraTools);

      terminalPackage =
        if cfg.installTerminalEmulator && cfg.terminalEmulator != "auto"
        then [ (desktop.getTerminalPackage cfg.terminalEmulator) ]
        else [];

      guiWrapper = optional cfg.createGuiWrapper
        (desktop.makeTerminalWrapper {
          terminalEmulator = cfg.terminalEmulator;
          nvimPackage = cfg.package;
        });

      selectedTerminal =
        if cfg.terminalEmulator == "auto"
        then desktop.detectTerminal config.home.packages
        else cfg.terminalEmulator;

      terminal = desktop.terminalEmulators.${selectedTerminal};
      execCommand = "${terminal.command} ${cfg.package}/bin/nvim %F";

      baseMimeTypes = [
        "text/plain" "text/x-markdown" "text/markdown" "text/x-tex"
        "text/x-chdr" "text/x-csrc" "text/x-c++hdr" "text/x-c++src"
        "text/x-java" "text/x-python" "text/x-lua" "text/x-nix"
        "text/x-haskell" "text/x-shellscript" "application/x-shellscript"
        "text/x-lisp" "text/x-scheme" "application/json" "text/csv"
        "text/x-yaml" "text/yaml" "application/x-yaml"
      ];
    in {
      home.packages = basePackages ++ terminalPackage ++ guiWrapper;

      home.sessionVariables = mkIf cfg.setDefaultEditor {
        EDITOR = "nvim";
        VISUAL = "nvim";
      };

      programs.bash.shellAliases = cfg.shellAliases;
      programs.zsh.shellAliases = cfg.shellAliases;
      programs.fish.shellAliases = cfg.shellAliases;

      xdg.configFile."nvim/lua/user.lua" = mkIf (cfg.extraConfig != "") {
        text = cfg.extraConfig;
      };

      xdg.desktopEntries = mkIf cfg.enableDesktopEntry {
        nvim = {
          name = "Neovim";
          genericName = "Text Editor";
          comment = "Edit text files with Neovim in ${terminal.name}";
          exec = execCommand;
          icon = "nvim";
          terminal = false;
          categories = [ "Utility" "TextEditor" "Development" "ConsoleOnly" ];
          mimeType = baseMimeTypes ++ cfg.extraMimeTypes;
          startupNotify = false;
          keywords = [ "vim" "neovim" "editor" "text" "code" "development" ];
        };
      };
    }
  );
}
