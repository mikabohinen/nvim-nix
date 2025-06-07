# lib/plugin-management.nix
# Nix-based plugin management utilities

{ pkgs, lib }:

let
  # Create a plugin management utility with total counts
  makePluginUtils = pluginSources: nixpkgsPluginNames: pkgs.writeShellScriptBin "nvim-plugin-utils" ''
    #!/usr/bin/env bash
    set -euo pipefail

    SCRIPT_DIR="$(cd "$(dirname "''${BASH_SOURCE[0]}")" && pwd)"

    # Colors
    GREEN='\033[0;32m'
    BLUE='\033[0;34m'
    YELLOW='\033[1;33m'
    CYAN='\033[0;36m'
    NC='\033[0m'

    log() { echo -e "''${BLUE}[$(date +'%H:%M:%S')]''${NC} $1"; }
    success() { echo -e "''${GREEN}✓''${NC} $1"; }
    warning() { echo -e "''${YELLOW}⚠''${NC} $1"; }
    info() { echo -e "''${CYAN}ℹ''${NC} $1"; }

    show_help() {
      cat << 'EOF'
nvim-plugin-utils - Nix-based plugin management

Commands:
  list              List all plugins with versions
  show <plugin>     Show detailed info for a plugin
  update-info       Show how to update plugin versions
  check-updates     Check for available updates (requires internet)
  debug-updates     Debug version of update checking with verbose output
  stats             Show plugin statistics
  help              Show this help

Plugin Management:
  To add a plugin:    Edit plugins.nix and add to pluginSources
  To remove a plugin: Edit plugins.nix and remove from pluginSources
  To update a plugin: Use 'update-info' command for instructions

Examples:
  nvim-plugin-utils list
  nvim-plugin-utils show vim-surround
  nvim-plugin-utils stats
  nvim-plugin-utils update-info
EOF
    }

    show_stats() {
      local local_count=${toString (lib.length (lib.attrNames pluginSources))}
      local nixpkgs_count=${toString (lib.length nixpkgsPluginNames)}
      local total_count=$((local_count + nixpkgs_count))

      log "Plugin Statistics:"
      echo
      info "Local plugins (managed via plugins.nix): $local_count"
      info "Nixpkgs plugins (complex/built plugins): $nixpkgs_count"
      success "Total plugins: $total_count"
      echo
      echo "Local plugins:"
      ${lib.concatStringsSep "\n" (lib.mapAttrsToList (name: source: ''
        echo "  • ${name} (${source.owner}/${source.repo})"'') pluginSources)}
      echo
      echo "Nixpkgs plugins:"
      ${lib.concatStringsSep "\n" (map (name: ''
        echo "  • ${name} (from nixpkgs)"'') nixpkgsPluginNames)}
    }

    list_plugins() {
      local local_count=${toString (lib.length (lib.attrNames pluginSources))}
      local nixpkgs_count=${toString (lib.length nixpkgsPluginNames)}
      local total_count=$((local_count + nixpkgs_count))

      log "All installed plugins (Total: $total_count):"
      echo
      info "Local plugins ($local_count):"
      ${lib.concatStringsSep "\n" (lib.mapAttrsToList (name: source: ''
        echo "  ${name}"
        echo "    Repository: ${source.owner}/${source.repo}"
        echo "    Commit: ${source.rev}"
        echo "    URL: https://github.com/${source.owner}/${source.repo}"
        echo
      '') pluginSources)}

      info "Nixpkgs plugins ($nixpkgs_count):"
      ${lib.concatStringsSep "\n" (map (name: ''
        echo "  ${name}"
        echo "    Source: nixpkgs (pre-built)"
        echo "    Management: Automatic via Nix"
        echo
      '') nixpkgsPluginNames)}
    }

    show_plugin() {
      local plugin="$1"
      case "$plugin" in
        ${lib.concatStringsSep "\n        " (lib.mapAttrsToList (name: source: ''
          ${name})
            echo "Plugin: ${name}"
            echo "Repository: ${source.owner}/${source.repo}"
            echo "Current commit: ${source.rev}"
            echo "GitHub URL: https://github.com/${source.owner}/${source.repo}"
            echo "Commit URL: https://github.com/${source.owner}/${source.repo}/commit/${source.rev}"
            ;;'') pluginSources)}
        *)
          warning "Plugin '$plugin' not found"
          echo "Available plugins: ${lib.concatStringsSep ", " (lib.attrNames pluginSources)}"
          exit 1
          ;;
      esac
    }

    show_update_info() {
      log "Plugin Update Process:"
      echo
      echo "Nvim-nix uses Nix for declarative plugin management with automatic loading."
      echo "To update plugins, you need to edit plugins.nix with new commit hashes."
      echo
      echo "Update process:"
      echo "1. Find the plugin's latest commit on GitHub"
      echo "2. Update the 'rev' field in plugins.nix"
      echo "3. Set 'sha256 = lib.fakeHash' temporarily"
      echo "4. Run 'nix build .#neovim' to get the correct hash"
      echo "5. Update the sha256 field with the correct value"
      echo
      echo "Helper commands for each plugin:"
      echo
      ${lib.concatStringsSep "\n" (lib.mapAttrsToList (name: source: ''
        echo "# ${name}"
        echo "nix-prefetch-github ${source.owner} ${source.repo} --rev \$(curl -s https://api.github.com/repos/${source.owner}/${source.repo}/commits/\$(curl -s https://api.github.com/repos/${source.owner}/${source.repo} | jq -r .default_branch) | jq -r .sha)"
        echo
      '') pluginSources)}

      echo "Example plugins.nix update:"
      echo "  vim-surround = {"
      echo "    owner = \"tpope\";"
      echo "    repo = \"vim-surround\";"
      echo "    rev = \"NEW_COMMIT_HASH_HERE\";"
      echo "    sha256 = lib.fakeHash;  # Will get correct hash from build error"
      echo "  };"
      echo
      echo "Note: All plugins in the 'start' list are automatically loaded by Neovim."
      echo "No manual :packadd commands needed!"
    }

    check_updates() {
      if ! command -v curl >/dev/null 2>&1 || ! command -v jq >/dev/null 2>&1; then
        warning "curl and jq are required for checking updates"
        exit 1
      fi

      log "Checking for plugin updates..."
      echo

      ${lib.concatStringsSep "\n" (lib.mapAttrsToList (name: source: ''
        echo -n "Checking ${name}... "

        # First get the default branch
        default_branch=$(curl -s "https://api.github.com/repos/${source.owner}/${source.repo}" | jq -r '.default_branch // "master"' 2>/dev/null)

        if [[ "$default_branch" == "null" || -z "$default_branch" ]]; then
          echo "❌ Failed to get default branch"
          continue
        fi

        # Then get the latest commit on that branch
        latest=$(curl -s "https://api.github.com/repos/${source.owner}/${source.repo}/commits/$default_branch" | jq -r '.sha // "error"' 2>/dev/null)

        if [[ "$latest" == "error" || "$latest" == "null" || -z "$latest" ]]; then
          echo "❌ Failed to fetch latest commit"
        elif [[ "$latest" == "${source.rev}" ]]; then
          echo "✅ Up to date"
        else
          echo "🔄 Update available"
          echo "    Current: ${source.rev}"
          echo "    Latest:  $latest"
        fi
      '') pluginSources)}
    }

    debug_updates() {
      if ! command -v curl >/dev/null 2>&1 || ! command -v jq >/dev/null 2>&1; then
        warning "curl and jq are required for checking updates"
        exit 1
      fi

      log "Debug: Checking for plugin updates with verbose output..."
      echo

      ${lib.concatStringsSep "\n" (lib.mapAttrsToList (name: source: ''
        echo "=== Debugging ${name} ==="
        echo "Repository: ${source.owner}/${source.repo}"
        echo "Current commit: ${source.rev}"
        echo

        # Test basic API access
        echo "Testing API access..."
        repo_info=$(curl -s "https://api.github.com/repos/${source.owner}/${source.repo}")
        if [[ $? -ne 0 ]]; then
          echo "❌ Failed to connect to GitHub API"
          continue
        fi

        # Check if repo exists
        if echo "$repo_info" | jq -e '.message' >/dev/null 2>&1; then
          echo "❌ Repository error: $(echo "$repo_info" | jq -r '.message')"
          continue
        fi

        # Get default branch
        echo "Getting default branch..."
        default_branch=$(echo "$repo_info" | jq -r '.default_branch // "master"')
        echo "Default branch: $default_branch"

        # Get latest commit
        echo "Getting latest commit on $default_branch..."
        commit_info=$(curl -s "https://api.github.com/repos/${source.owner}/${source.repo}/commits/$default_branch")
        latest=$(echo "$commit_info" | jq -r '.sha // "error"')

        if [[ "$latest" == "error" || "$latest" == "null" ]]; then
          echo "❌ Failed to get latest commit"
          echo "Response: $commit_info"
        else
          echo "Latest commit: $latest"
          if [[ "$latest" == "${source.rev}" ]]; then
            echo "✅ Up to date"
          else
            echo "🔄 Update available"
          fi
        fi
        echo
      '') pluginSources)}
    }

    case "''${1:-help}" in
      list) list_plugins ;;
      show)
        if [[ $# -lt 2 ]]; then
          warning "Usage: nvim-plugin-utils show <plugin-name>"
          exit 1
        fi
        show_plugin "$2"
        ;;
      stats) show_stats ;;
      update-info) show_update_info ;;
      check-updates) check_updates ;;
      debug-updates) debug_updates ;;
      help|--help|-h) show_help ;;
      *)
        warning "Unknown command: $1"
        show_help
        exit 1
        ;;
    esac
  '';

in rec {
  # Create a plugin definition from GitHub info
  makePluginSource = { owner, repo, rev, sha256 ? lib.fakeHash }: {
    inherit owner repo rev sha256;
  };

  # Fetch latest commit for a plugin (for updates)
  # This uses nix-prefetch-github at build time
  fetchLatestCommit = { owner, repo, branch ? "master" }:
    let
      # This will need to be run manually for updates, but provides the structure
      prefetchCmd = pkgs.writeShellScript "fetch-latest-${repo}" ''
        ${pkgs.nix-prefetch-github}/bin/nix-prefetch-github ${owner} ${repo} --rev ${branch}
      '';
    in {
      inherit owner repo branch;
      updateCommand = prefetchCmd;
      description = "Run this to get latest commit info for ${owner}/${repo}";
    };

  # Generate plugin update commands
  makeUpdateCommands = pluginSources:
    lib.mapAttrs (name: source:
      fetchLatestCommit {
        inherit (source) owner repo;
        branch = source.branch or "master";
      }
    ) pluginSources;

  # Create a development shell with plugin management tools
  makePluginDevShell = pluginSources: nixpkgsPluginNames: pkgs.mkShell {
    buildInputs = with pkgs; [
      nix-prefetch-github
      curl
      jq
      git
      (makePluginUtils pluginSources nixpkgsPluginNames)
    ];

    shellHook = ''
      echo "🔌 Plugin Management Environment"
      echo "Available commands:"
      echo "  nvim-plugin-utils list          # List all plugins"
      echo "  nvim-plugin-utils stats         # Show plugin statistics"
      echo "  nvim-plugin-utils check-updates # Check for updates"
      echo "  nvim-plugin-utils update-info   # Show update process"
      echo ""
      echo "Local plugins: ${toString (lib.length (lib.attrNames pluginSources))}"
      echo "Nixpkgs plugins: ${toString (lib.length nixpkgsPluginNames)}"
      echo "Total plugins: ${toString (lib.length (lib.attrNames pluginSources) + lib.length nixpkgsPluginNames)}"
      echo ""
      echo "Edit plugins.nix to add/remove/update local plugins"
      echo "Edit default.nix to modify nixpkgs plugins"
      echo ""
      echo "ℹ️  All plugins are automatically loaded by Neovim (no :packadd needed)"
    '';
  };

  # Template for adding a new plugin
  makePluginTemplate = { owner, repo, description ? "" }: ''
    # Add this to plugins.nix pluginSources:

    ${repo} = {
      owner = "${owner}";
      repo = "${repo}";
      rev = "COMMIT_HASH";  # Get with: nix-prefetch-github ${owner} ${repo}
      sha256 = lib.fakeHash; # Will be computed automatically by Nix
    };

    ${if description != "" then "# ${description}" else ""}
    # Plugin will be automatically loaded on Neovim startup (no :packadd needed)
  '';

  # Validation functions
  validatePluginSource = name: source:
    let
      required = [ "owner" "repo" "rev" "sha256" ];
      missing = lib.filter (field: !(source ? ${field})) required;
    in
    if missing == []
    then true
    else throw "Plugin '${name}' missing required fields: ${lib.concatStringsSep ", " missing}";

  validateAllPlugins = pluginSources:
    lib.all (lib.uncurry validatePluginSource) (lib.attrsToList pluginSources);

  # Export the main functions
  inherit makePluginUtils;
}
