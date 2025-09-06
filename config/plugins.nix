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
      rev = "65846025c15494983dafe5e3b46c8f88ab2e9635";
      sha256 = "sha256-G/dmkq1KtSHIl+I5p3LfO6mGPS3eyLRbEEsuLbTpGlk=";
    };

    vim-fugitive = {
      owner = "tpope";
      repo = "vim-fugitive";
      rev = "4a745ea72fa93bb15dd077109afbb3d1809383f2";
      sha256 = "sha256-1AteNwnc7lCHLIwM8Ejm2T9VTIDM+CeAfvAUeSQRFKE=";
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

in
lib.attrValues builtPlugins
