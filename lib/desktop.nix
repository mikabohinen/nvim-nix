# lib/desktop.nix
# Desktop integration utilities for GUI environments

{ pkgs, lib }:

rec {
  # Common terminal emulators and their command syntax
  terminalEmulators = {
    kitty = {
      package = pkgs.kitty;
      command = "kitty -e";
      name = "Kitty";
    };
    alacritty = {
      package = pkgs.alacritty;
      command = "alacritty -e";
      name = "Alacritty";
    };
    wezterm = {
      package = pkgs.wezterm;
      command = "wezterm start --";
      name = "WezTerm";
    };
    gnome-terminal = {
      package = pkgs.gnome-terminal;
      command = "gnome-terminal --";
      name = "GNOME Terminal";
    };
    konsole = {
      package = pkgs.kdePackages.konsole or pkgs.konsole;
      command = "konsole -e";
      name = "Konsole";
    };
    xterm = {
      package = pkgs.xterm;
      command = "xterm -e";
      name = "XTerm";
    };
    terminator = {
      package = pkgs.terminator;
      command = "terminator -e";
      name = "Terminator";
    };
    st = {
      package = pkgs.st;
      command = "st -e";
      name = "Simple Terminal";
    };
  };

  # Detect the best available terminal emulator
  detectTerminal = availablePackages:
    let
      # Preference order (modern, feature-rich terminals first)
      preferenceOrder = [ "kitty" "alacritty" "wezterm" "gnome-terminal" "konsole" "terminator" "xterm" "st" ];

      isAvailable = name:
        let term = terminalEmulators.${name}; in
        lib.any (pkg: pkg.pname or pkg.name == term.package.pname or term.package.name) availablePackages;

      availableTerms = lib.filter isAvailable preferenceOrder;
    in
    if availableTerms != []
    then lib.head availableTerms
    else "xterm"; # fallback

  # Create desktop entry for nvim with terminal wrapper
  makeDesktopEntry = {
    terminalEmulator ? "auto",
    availablePackages ? [],
    extraMimeTypes ? [],
    nvimPackage
  }:
    let
      # Determine which terminal to use
      selectedTerminal =
        if terminalEmulator == "auto"
        then detectTerminal availablePackages
        else terminalEmulator;

      terminal = terminalEmulators.${selectedTerminal};

      # Create the exec command
      execCommand = "${terminal.command} ${nvimPackage}/bin/nvim %F";

      # Base MIME types we always support
      baseMimeTypes = [
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
        "text/x-lua"
        "text/x-nix"
        "text/x-haskell"
        "text/x-shellscript"
        "application/x-shellscript"
        "text/x-lisp"
        "text/x-scheme"
        "application/json"
        "text/csv"
        "text/x-yaml"
        "text/yaml"
        "application/x-yaml"
      ];
    in {
      name = "Neovim";
      desktopName = "Neovim (${terminal.name})";
      genericName = "Text Editor";
      comment = "Edit text files with Neovim in ${terminal.name}";
      exec = execCommand;
      icon = "nvim";
      terminal = false; # We handle the terminal ourselves
      categories = [ "Utility" "TextEditor" "Development" "ConsoleOnly" ];
      mimeType = baseMimeTypes ++ extraMimeTypes;

      # Additional desktop entry properties
      startupNotify = false;
      noDisplay = false;

      # Keywords for better searchability
      keywords = [ "vim" "neovim" "editor" "text" "code" "development" ];

      # Actions for different use cases
      actions = {
        new-window = {
          name = "New Window";
          exec = "${terminal.command} ${nvimPackage}/bin/nvim";
        };
        edit-config = {
          name = "Edit Configuration";
          exec = "${terminal.command} ${nvimPackage}/bin/nvim ~/.config/nvim/init.lua";
        };
      };
    };

  # Create multiple desktop entries for different use cases
  makeDesktopEntries = {
    terminalEmulator ? "auto",
    availablePackages ? [],
    nvimPackage,
    createVariants ? true
  }:
    let
      mainEntry = makeDesktopEntry {
        inherit terminalEmulator availablePackages nvimPackage;
      };

      # Create additional entries for specific use cases
      variants = lib.optionalAttrs createVariants {
        nvim-diff = mainEntry // {
          name = "nvim-diff";
          desktopName = "Neovim Diff";
          comment = "Compare files with Neovim";
          exec = let terminal = terminalEmulators.${
            if terminalEmulator == "auto"
            then detectTerminal availablePackages
            else terminalEmulator
          }; in "${terminal.command} ${nvimPackage}/bin/nvim -d %F";
          mimeType = [];
          noDisplay = true; # Hidden by default, for file manager integration
        };

        nvim-readonly = mainEntry // {
          name = "nvim-readonly";
          desktopName = "Neovim (Read-only)";
          comment = "View files with Neovim in read-only mode";
          exec = let terminal = terminalEmulators.${
            if terminalEmulator == "auto"
            then detectTerminal availablePackages
            else terminalEmulator
          }; in "${terminal.command} ${nvimPackage}/bin/nvim -R %F";
          noDisplay = true;
        };
      };
    in
    { nvim = mainEntry; } // variants;

  # Terminal emulator package from name
  getTerminalPackage = name:
    if terminalEmulators ? ${name}
    then terminalEmulators.${name}.package
    else throw "Unknown terminal emulator: ${name}";

  # Validate terminal emulator choice
  validateTerminal = name:
    if name == "auto" || terminalEmulators ? ${name}
    then true
    else throw "Invalid terminal emulator '${name}'. Available: ${lib.concatStringsSep ", " (["auto"] ++ lib.attrNames terminalEmulators)}";

  # Create a wrapper script for command line usage
  makeTerminalWrapper = { terminalEmulator, nvimPackage }:
    pkgs.writeShellScriptBin "nvim-gui" ''
      # Launch nvim in the specified terminal emulator
      ${if terminalEmulator == "auto"
        then ''
          # Auto-detect available terminal
          for term in kitty alacritty wezterm gnome-terminal konsole terminator xterm; do
            if command -v "$term" >/dev/null 2>&1; then
              case "$term" in
                kitty) exec kitty -e ${nvimPackage}/bin/nvim "$@" ;;
                alacritty) exec alacritty -e ${nvimPackage}/bin/nvim "$@" ;;
                wezterm) exec wezterm start -- ${nvimPackage}/bin/nvim "$@" ;;
                gnome-terminal) exec gnome-terminal -- ${nvimPackage}/bin/nvim "$@" ;;
                konsole) exec konsole -e ${nvimPackage}/bin/nvim "$@" ;;
                terminator) exec terminator -e "${nvimPackage}/bin/nvim $*" ;;
                xterm) exec xterm -e ${nvimPackage}/bin/nvim "$@" ;;
              esac
            fi
          done
          echo "No suitable terminal emulator found!" >&2
          exit 1
        ''
        else
          let terminal = terminalEmulators.${terminalEmulator}; in
          "exec ${terminal.command} ${nvimPackage}/bin/nvim \"$@\""
      }
    '';
}
