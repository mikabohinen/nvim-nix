# Nvim-Nix

A reproducible, declarative Neovim configuration using Nix flakes.

## Features

- 🔄 **Reproducible**: Same setup on any machine with Nix
- 🧩 **Modular**: Organized language support with LSP, formatters, and treesitter
- 🔌 **Extensible**: Easy to add new languages and plugins
- 🚀 **Batteries included**: Pre-configured for multiple languages
- 📦 **Declarative**: Configuration defined entirely in Nix

## Supported Languages

- Bash
- Haskell
- Java
- Lisp
- Markdown
- Nix
- LaTeX
- Lua
- Agda (with dedicated Cornelis support)

Each language comes with:
- LSP server (where applicable)
- Treesitter parser
- Code formatter

## Installation

### Prerequisites

- [Nix package manager](https://nixos.org/download.html) with flakes enabled

### As a standalone application

```bash
# Run directly
nix run codeberg:mikabo/nvim-nix

# Install to your profile
nix profile install github:yourusername/nvim-nix
```

### As a NixOS module

Add to your `flake.nix`:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nvim-nix.url = "codeberg:mikabo/nvim-nix";
  };

  outputs = { self, nixpkgs, nvim-nix, ... }: {
    nixosConfigurations.yourhostname = nixpkgs.lib.nixosSystem {
      # ...
      modules = [
        # ...
        nvim-nix.nixosModules.default
        {
          programs.mynvim.enable = true;
        }
      ];
    };
  };
}
```

### In Home Manager

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    nvim-nix.url = "github:yourusername/nvim-nix";
  };
  
  outputs = { nixpkgs, home-manager, nvim-nix, ... }: {
    homeConfigurations."yourusername" = home-manager.lib.homeManagerConfiguration {
      # ...
      modules = [
        {
          home.packages = [ nvim-nix.packages.${system}.default ];
        }
      ];
    };
  };
}
```

## Key Bindings

### General

- `<Space>` - Leader key
- `,` - Local leader key

### LSP

- `<leader>e` - Show diagnostic at cursor
- `[d` - Go to previous diagnostic
- `]d` - Go to next diagnostic
- `<leader>q` - Show diagnostics in location list

### Formatting

- `<leader>cf` - Format current buffer

### File Navigation

- `<leader>ff` - Find files
- `<leader>fg` - Live grep
- `<leader>fb` - Browse buffers

### Agda-specific

- `<leader>l` - Load file
- `<leader>r` - Refine
- `<leader>d` / `<leader>m` - Make case
- `<leader>,` - Type context
- `<leader>.` - Type context infer
- `<leader>n` - Solve
- `<leader>a` - Auto
- `gd` - Go to definition
- `[/` - Previous goal
- `]/` - Next goal
- `<C-A>` - Increment
- `<C-X>` - Decrement

## Customization

### Adding a New Language

Edit `default.nix` and add a new entry to `supportedLanguages`:

```nix
python = {
  lsp = {
    package = pkgs.nodePackages.pyright;
    serverName = "pyright";
  };
  treesitter = "python";
  formatter = {
    name = "black";
    package = pkgs.black;
  };
};
```

### Adding Plugins

Edit the `plugins` list in `default.nix`:

```nix
plugins = with pkgs.vimPlugins; [
  # Existing plugins...
  
  # Your new plugins
  vim-fugitive
  gitsigns-nvim
];
```

And add their configuration to `neovimConfig`:

```nix
neovimConfig = pkgs.writeText "init.lua" ''
  -- Existing config...
  
  -- Git integration
  require('gitsigns').setup()
  
  -- Fugitive mappings
  vim.keymap.set('n', '<leader>gs', ':Git<CR>')
'';
```

## Development

Clone and enter development shell:

```bash
git clone https://github.com/yourusername/nvim-nix.git
cd nvim-nix
nix develop
```

Test your changes:

```bash
nix run .
```

## License

MIT
