# Nvim-Nix

A reproducible, declarative Neovim configuration using Nix flakes, following minimalist vim philosophy with essential modern enhancements.

## Features

- 🔄 **Reproducible**: Same setup on any machine with Nix
- 🧩 **Modular**: Organized language support with LSP, formatters, and treesitter
- 🔌 **Extensible**: Easy to add new languages and plugins
- 🚀 **Batteries included**: Pre-configured for multiple languages
- 📦 **Declarative**: Configuration defined entirely in Nix
- 🎯 **Minimalist**: Expert-level vim foundation with essential Lua enhancements
- 🔧 **Nix Integration**: Built-in commands for Nix development workflow

## Philosophy

This configuration follows the minimalist vim philosophy, building upon Tim Pope's sensible.vim principles while incorporating essential modern features that require Lua. The core is pure vimscript for maximum portability and expert-level efficiency, with targeted Lua enhancements for LSP, treesitter, and modern editing features.

## Supported Languages

- **Bash** - LSP (bashls), treesitter, formatter (shfmt)
- **Haskell** - LSP (hls), treesitter, formatter (fourmolu)
- **Java** - LSP (jdtls), treesitter, formatter (google-java-format)
- **Common Lisp** - treesitter, REPL integration (Conjure + SWANK)
- **Markdown** - treesitter, formatter (prettier)
- **Nix** - LSP (nixd), treesitter, formatter (nixpkgs-fmt)
- **LaTeX** - LSP (texlab), treesitter
- **Lua** - formatter (stylua)
- **Python** - LSP (pyright), treesitter, formatter (black)
- **Agda** - Dedicated Cornelis support with proof assistant integration

Each language includes appropriate tooling:

- LSP server (where applicable)
- Treesitter parser for syntax highlighting
- Code formatter
- Language-specific features and key bindings

## Essential Plugins

Following expert minimalism principles, only essential plugins are included:

- **LSP & Language Support**: nvim-lspconfig, nvim-treesitter, nvim-treesitter-textobjects
- **Expert Editing**: vim-surround, nvim-autopairs, vim-vinegar
- **Git Integration**: gitsigns-nvim, vim-fugitive
- **Specialized Language Support**: cornelis (Agda), conjure (Lisp REPL), vim-sexp
- **Tool Integration**: conform-nvim (formatting), which-key-nvim (learning aid)
- **Aesthetics**: nightfox-nvim colorscheme

## Installation

### Prerequisites

- [Nix package manager](https://nixos.org/download.html) with flakes enabled

### As a standalone application

```bash
# Run directly
nix run github:mikabohinen/nvim-nix

# Install to your profile
nix profile install github:mikabohinen/nvim-nix
```

### As a NixOS module

Add to your `flake.nix`:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nvim-nix.url = "github:mikabohinen/nvim-nix";
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

## Key Bindings

### Core Philosophy

This configuration follows vim expert practices:

- **Leader key**: `<Space>` for global operations
- **Local leader**: `,` for filetype-specific operations
- **Native vim commands**: Prioritized for file finding, searching, and navigation
- **Consistent patterns**: Similar operations use similar key combinations

### Essential Navigation

- `<leader>f` - Find files (`:find **/*`)
- `<leader>F` - Find files recursive
- `<leader>b` - Switch buffer (`:buffer`)
- `<leader>B` - Switch buffer in split
- `[b` / `]b` - Previous/next buffer
- `<leader>d` - Delete buffer

### Search Operations

- `<leader>s` - System grep
- `<leader>S` - Search in project (`:vimgrep`)
- `<Esc><Esc>` - Clear search highlighting
- `/` - Enhanced search with very magic mode

### Quickfix & Location Lists

- `<leader>q` / `<leader>Q` - Open/close quickfix
- `<leader>l` / `<leader>L` - Open/close location list
- `]q` / `[q` - Next/previous quickfix
- `]l` / `[l` - Next/previous location list
- `<leader>c` - Toggle quickfix

### LSP (when available)

- `gd` - Go to definition
- `gr` - Go to references
- `gi` - Go to implementation
- `K` - Hover documentation
- `<leader>rn` - Rename symbol
- `<leader>ca` - Code actions

### Formatting

- `<leader>cf` - Format current buffer (manual)
- Automatic formatting on save (configurable per filetype)

### Git Integration

- `<leader>gb` - Toggle git blame
- `<leader>gp` - Preview hunk
- `<leader>gr` - Reset hunk
- `<leader>gs` - Stage hunk
- `<leader>gu` - Undo stage hunk
- `[h` / `]h` - Previous/next hunk

### Treesitter Text Objects

- `af` / `if` - Around/inside function
- `ac` / `ic` - Around/inside class
- `al` / `il` - Around/inside loop
- `aa` / `ia` - Around/inside parameter
- `]f` / `[f` - Next/previous function
- `]c` / `[c` - Next/previous class

### Agda-specific (Cornelis)

- `<leader>l` - Load file
- `<leader>r` - Refine goal
- `<leader>,` - Type context
- `gd` - Go to definition
- `[/` / `]/` - Previous/next goal

### Common Lisp (Conjure + SWANK)

- `<localleader>ee` - Evaluate form
- `<localleader>cf` - Connect to SWANK server
- `:SwankStart` - Start SWANK server

### Nix Development

- `:NixRun [target]` - Run nix flake target
- `:NixBuild [target]` - Build nix flake target
- `:NixShell [target]` - Enter nix develop shell
- `:NixUpdate [input]` - Update flake.lock (optionally specific input)
- `:NixCheck` - Check flake for issues
- `:NixClean` - Clean nix store (with confirmation)
- `:NixInfo [target]` - Show flake outputs and structure
- `:NixSearch <term>` - Search nixpkgs for packages
- `:NixEval <expr>` - Evaluate nix expressions
- `:NixWhyDepends <source> <target>` - Show dependency chain
- `:EditFlake` / `:EditDefault` - Quick edit flake.nix/default.nix

**Nix Leader Mappings** (global):

- `<leader>nr` - `:NixRun ` (with prompt)
- `<leader>nb` - `:NixBuild ` (with prompt)
- `<leader>ns` - Enter nix develop shell
- `<leader>nu` - Update flake.lock
- `<leader>nc` - Check flake
- `<leader>ni` - Show flake info
- `<leader>nS` - Search packages (with prompt)
- `<leader>ne` - Evaluate expression (with prompt)
- `<leader>nC` - Clean nix store
- `<leader>ef` - Edit flake.nix
- `<leader>ed` - Edit default.nix

**Nix File Mappings** (in .nix files):

- `<localleader>r` - Run current flake
- `<localleader>b` - Build current flake
- `<localleader>c` - Check current flake
- `<localleader>u` - Update flake.lock
- `<localleader>s` - Enter nix shell
- `<localleader>i` - Show flake info

## Development Workflow

### For Nix Projects

1. **Quick Testing**: `:NixRun` or `<leader>nr` to test your current flake
2. **Building**: `:NixBuild .#package` or `<leader>nb` to build specific outputs
3. **Development**: `:NixShell` or `<leader>ns` to enter development environment
4. **Updates**: `:NixUpdate` or `<leader>nu` to update dependencies
5. **Checking**: `:NixCheck` or `<leader>nc` to validate your flake
6. **Package Search**: `:NixSearch <term>` or `<leader>nS` to find packages

**In .nix files**, use local leader mappings for quick access:

- `<localleader>r` to run current flake
- `<localleader>b` to build current flake
- `<localleader>c` to check current flake

### For General Development

1. Use native vim commands for file navigation (`:find`, `:buffer`)
2. Leverage quickfix lists for project-wide operations
3. Use LSP features when available, fall back to native vim
4. Format code with `<leader>cf` or rely on format-on-save
5. Access project files quickly with `<leader>ef` (flake.nix) and `<leader>ed` (default.nix)

## Customization

### Adding a New Language

Edit `default.nix` and add a new entry to `supportedLanguages`:

```nix
rust = {
  lsp = {
    package = pkgs.rust-analyzer;
    serverName = "rust_analyzer";
  };
  treesitter = "rust";
  formatter = {
    name = "rustfmt";
    package = pkgs.rustfmt;
  };
};
```

### Adding Plugins

Edit the `plugins` list in `default.nix`:

```nix
plugins = with pkgs.vimPlugins; [
  # Existing plugins...

  # Your new plugin
  vim-commentary
];
```

And add configuration to `neovimConfig` if needed.

### Customizing Key Bindings

Core key bindings are defined in `vimrc.vim` following vim conventions. Language-specific and plugin bindings are configured in the Lua section of `default.nix`.

**To add the Nix development commands**: Add the vimscript Nix integration code to the end of your `vimrc.vim` file. This provides comprehensive Nix workflow integration using traditional vim patterns.

### Adding Custom Commands

Follow the vimscript patterns in `vimrc.vim`:

```vim
" Simple command
command! MyCommand echo "Hello"

" Command with arguments and completion
command! -nargs=? -complete=file MyEdit edit <args>

" Command using helper function
command! MyComplex call s:MyHelper()
function! s:MyHelper()
  " Complex logic here
endfunction
```

## File Structure

- `default.nix` - Main Neovim configuration and package definition
- `flake.nix` - Nix flake with inputs and outputs
- `vimrc.vim` - Core vim configuration following traditional patterns

## Contributing

This configuration follows these principles:

1. **Vim-first**: Traditional vim patterns and commands are preferred
2. **Minimal dependencies**: Only essential plugins that provide significant value
3. **Reproducible**: Everything defined declaratively in Nix
4. **Expert-friendly**: Optimized for efficiency and muscle memory
5. **Language-agnostic**: Consistent patterns across all supported languages
6. **Vimscript for commands**: Use vimscript for shell integration and commands, Lua only for features requiring it

When contributing:

- Prefer native vim solutions over plugin dependencies
- Use vimscript for custom commands and shell integration
- Reserve Lua for LSP, treesitter, and plugin configuration that requires it
- Ensure all changes are reproducible across systems
- Follow the existing patterns for language support
- Document any new key bindings or features

## License

MIT
