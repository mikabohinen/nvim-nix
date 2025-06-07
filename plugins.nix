# plugins.nix
# Declarative plugin definitions with exact version control

{ pkgs, lib }:

let
  pluginSources = {
    vim-surround = {
      owner = "tpope";
      repo = "vim-surround";
      rev = "3d188ed2113431cf8dac77be61b842acb64433d9";
      sha256 = "sha256-DZE5tkmnT+lAvx/RQHaDEgEJXRKsy56KJY919xiH1lE=";
    };

    vim-vinegar = {
      owner = "tpope";
      repo = "vim-vinegar";
      rev = "bb1bcddf43cfebe05eb565a84ab069b357d0b3d6";
      sha256 = "sha256-rpHVTwXRFfWlBbduJPSqtDjDEQTjwpi6mQ2LQJvRZiA=";
    };

    vim-repeat = {
      owner = "tpope";
      repo = "vim-repeat";
      rev = "24afe922e6a05891756ecf331f39a1f6743d3d5a";
      sha256 = "sha256-8rfZa3uKXB3TRCqaDHZ6DfzNbm7WaYnLvmTNzYtnKHg=";
    };

    vim-fugitive = {
      owner = "tpope";
      repo = "vim-fugitive";
      rev = "46eaf8918b347906789df296143117774e827616";
      sha256 = "sha256-b6x8suCHRMYzqu/PGlt5FPg+7/CilkjWzlkBZ3i3H/c=";
    };

    vim-sexp = {
      owner = "guns";
      repo = "vim-sexp";
      rev = "14464d4580af43424ed8f2614d94e62bfa40bb4d";
      sha256 = "sha256-HRNzyh3M6KrPyoRmPNug3Qldc5hRim3out4vKG/PM40=";
    };
  };

  buildPlugin = name: source: pkgs.vimUtils.buildVimPlugin {
    pname = name;
    version = source.rev;
    src = pkgs.fetchFromGitHub {
      owner = source.owner;
      repo = source.repo;
      rev = source.rev;
      sha256 = source.sha256;
    };

    meta = with lib; {
      description = "Vim plugin ${name}";
      homepage = "https://github.com/${source.owner}/${source.repo}";
      license = licenses.vim;
      maintainers = [];
    };
  };

  builtPlugins = lib.mapAttrs buildPlugin pluginSources;

in rec {
  inherit pluginSources;

  plugins = builtPlugins;

  pluginList = lib.attrValues builtPlugins;

  utils = {
    listPlugins = lib.mapAttrsToList (name: source: {
      inherit name;
      inherit (source) owner repo rev;
      url = "https://github.com/${source.owner}/${source.repo}";
    }) pluginSources;

    pluginCount = lib.length (lib.attrNames pluginSources);

    hasPlugin = name: pluginSources ? ${name};

    getPlugin = name:
      if pluginSources ? ${name}
      then pluginSources.${name} // { inherit name; }
      else throw "Plugin '${name}' not found";
  };

  # Version info for debugging
  versionInfo = {
    pluginSources = pluginSources;
    pluginCount = utils.pluginCount;
    plugins = lib.attrNames pluginSources;
  };
}
