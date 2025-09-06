{ lib }:

{
  /*
    Extract components from language definitions into categorized lists.

    This function processes a structured language definition set and extracts
    different types of development tools into separate lists for easier consumption
    by the Neovim configuration.

    Type: extractComponents :: AttrSet -> { languageServers :: [Package]; treesitterParsers :: [String]; formatters :: [Package]; }

    Example:
      extractComponents {
        python = {
          lsp = { package = pkgs.pyright; serverName = "pyright"; };
          treesitter = "python";
          formatter = { package = pkgs.black; name = "black"; };
        };
        nix = {
          lsp = { package = pkgs.nixd; serverName = "nixd"; };
          treesitter = "nix";
        };
      }
      => {
           languageServers = [ pkgs.pyright pkgs.nixd ];
           treesitterParsers = [ "python" "nix" ];
           formatters = [ pkgs.black ];
         }
  */
  extractComponents = languages: {
    languageServers = builtins.filter (x: x != null) (
      builtins.map
        (lang: if builtins.hasAttr "lsp" lang then lang.lsp.package else null)
        (builtins.attrValues languages)
    );

    treesitterParsers = builtins.filter (x: x != null) (
      builtins.map
        (lang: if builtins.hasAttr "treesitter" lang then lang.treesitter else null)
        (builtins.attrValues languages)
    );

    formatters = builtins.filter (x: x != null) (
      builtins.map
        (lang: if builtins.hasAttr "formatter" lang then lang.formatter.package else null)
        (builtins.attrValues languages)
    );
  };

  /*
    Generate Lua code for LSP server setup from language definitions.

    This function takes structured language definitions and generates the corresponding
    Lua code that configures nvim-lspconfig for each language server. It handles
    optional settings and onInit callbacks.

    Type: generateLspSetup :: AttrSet -> String

    Example:
      generateLspSetup {
        python = {
          lsp = {
            package = pkgs.pyright;
            serverName = "pyright";
            settings = { python = { analysis = { autoSearchPaths = true; }; }; };
          };
        };
        lua = {
          lsp = {
            package = pkgs.lua-language-server;
            serverName = "lua_ls";
            onInit = ''
              function(client)
                client.config.settings.Lua = { runtime = { version = 'LuaJIT' } }
              end
            '';
          };
        };
      }
      => "lspconfig.pyright.setup({ settings = vim.fn.json_decode('{\"python\":{\"analysis\":{\"autoSearchPaths\":true}}}')})
          lspconfig.lua_ls.setup({on_init = function(client) client.config.settings.Lua = { runtime = { version = 'LuaJIT' } } end, settings = vim.fn.json_decode('{}')}))"
  */
  generateLspSetup = languages: builtins.concatStringsSep "\n" (
    builtins.map
      (name:
        let
          lang = languages.${name};
          hasLsp = builtins.hasAttr "lsp" lang;
          hasSettings = hasLsp && builtins.hasAttr "settings" lang.lsp;
          hasOnInit = hasLsp && builtins.hasAttr "onInit" lang.lsp;
          settingsJson = if hasSettings then builtins.toJSON lang.lsp.settings else "{}";
          onInitPart = if hasOnInit then "on_init = ${lang.lsp.onInit}," else "";
        in
        if hasLsp then
          "lspconfig.${lang.lsp.serverName}.setup({${onInitPart} settings = vim.fn.json_decode('${settingsJson}')})"
        else ""
      )
      (builtins.attrNames languages)
  );
}
