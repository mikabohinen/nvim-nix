# Nvim-Nix

A reproducible, declarative Neovim configuration using Nix flakes, following
minimalist vim philosophy with essential modern enhancements.

## Philosophy

This configuration follows a minimalist approach. It embodies the belief that
power comes from mastery of core tools, not accumulation of features.

### Core Principles

**Vim-First Approach**: Modern features supplement, never replace, core Vim functionality. File finding uses `:find **/*`, searching uses `:grep` and `:vimgrep`, navigation relies on native commands. LSP and Treesitter enhance this foundation without replacing it.

**Reproducible Development**: Nix ensures identical environments across machines. Every dependency, from language servers to formatters, is declaratively specified and automatically available.

**Structural Thinking**: The configuration is organized around how you actually work - finding, searching, navigating, editing. Key mappings follow consistent patterns that scale with complexity.

**Exceptions**: Only one language gets special treatment - Lisp. Vim's text objects and structural editing work so naturally with Lisp's uniform syntax that specialized tools like paredit aren't luxuries, they're baseline usability.

## Features

- 🔄 **Reproducible**: Same setup on any machine with Nix
- 🧩 **Modular**: Organized language support with LSP, formatters, and treesitter
- 🔌 **Extensible**: Easy to add new languages and plugins
- 🚀 **Batteries included**: Pre-configured for multiple languages
- 📦 **Declarative**: Configuration defined entirely in Nix
- 🔧 **Nix Integration**: Built-in commands for Nix development workflow

## Supported Languages

Each language includes appropriate tooling based on ecosystem maturity:

- **Bash** - LSP (bashls), treesitter, formatter (shfmt)
- **Haskell** - LSP (hls), treesitter, formatter (fourmolu)
- **Java** - LSP (jdtls), treesitter, formatter (google-java-format)
- **Common Lisp** - treesitter, structural editing
- **Markdown** - treesitter, formatter (prettier)
- **Nix** - LSP (nixd), treesitter, formatter (nixpkgs-fmt)
- **LaTeX** - LSP (texlab), treesitter
- **Lua** - formatter (stylua)
- **Python** - LSP (pyright), treesitter, formatter (black)

**Language Philosophy**: LSP + Treesitter + formatter is the standard approach. Lisp gets structural editing tools because Vim's text objects map perfectly to its uniform syntax. REPL development uses terminal integration rather than editor plugins.

## Essential Plugins

Only essential plugins are included:

**Modern Necessities** (what vimscript can't handle well):

- **nvim-lspconfig**: Language server integration
- **nvim-treesitter + textobjects**: Enhanced syntax and structural navigation
- **conform-nvim**: External formatter integration

**Editing** (amplify core Vim strengths):

- **vim-surround**: Text object manipulation
- **vim-repeat**: Quality of life addition
- **nvim-autopairs**: Intelligent bracket pairing
- **vim-vinegar**: Enhanced netrw
- **comment-nvim**: Structured commenting

**Development Integration** (essential workflow tools):

- **gitsigns-nvim + vim-fugitive**: Git integration
- **which-key-nvim**: Learning aid for discovering mappings

**Lisp Exception** (structural editing for uniform syntax):

- **vim-sexp + mappings**: Paredit-style editing for s-expressions

**Quality of Life**:

- **nightfox-nvim**: Modern colorscheme (nice to have some aesthetics)

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

### Philosophy: Consistent Patterns

Key bindings follow **functional grouping**:

- **`<leader>f*`**: All "finding" operations (files, buffers, search)
- **`<leader>g*`**: Git operations
- **`<leader>c*`**: Code operations
- **`<leader>n*`**: Nix development workflow
- **Navigation**: Native vim patterns (`]b`, `[q`, etc.)

### Core Finding Operations

**Leader key**: `<Space>` for global operations
**Local leader**: `,` for filetype-specific operations

```vim
" File finding (vim native)
<leader><leader>  " :find *
<leader>ff        " :find * (same as above)
<leader>fF        " :find **/* (recursive)

" Buffer operations
<leader>fb       " :buffer * (find and open)
<leader>fB       " :sbuffer * (find and split)
[b / ]b          " Previous/next buffer
<leader>bd       " Delete buffer

" Search operations
<leader>fw       " :grep "" . (project-wide search)
<leader>fW       " :vimgrep // **/* (vim's internal search)
<leader>fs       " :lgrep "" . (location list search)
<leader>fS       " :lvimgrep // **/* (location list vim search)
```

### Navigation & Lists

```vim
" Quickfix & Location Lists
<leader>q / <leader>Q   " Open/close quickfix
<leader>l / <leader>L   " Open/close location list
]q / [q                 " Next/previous quickfix
]l / [l                 " Next/previous location list
<leader>c               " Toggle quickfix
```

### LSP (when available)

```vim
gd               " Go to definition
gr               " Go to references
gi               " Go to implementation
K                " Hover documentation
<leader>rn       " Rename symbol
<leader>ca       " Code actions
```

### Code Operations

```vim
<leader>cf       " Format current buffer
<Esc><Esc>       " Clear search highlighting
/ and ?          " Enhanced search (very magic mode)
```

### Git Integration

```vim
<leader>gb       " Toggle git blame
<leader>gp       " Preview hunk
<leader>gr       " Reset hunk
<leader>gs       " Stage hunk
<leader>gu       " Undo stage hunk
[h / ]h          " Previous/next hunk
```

### Treesitter Text Objects

```vim
af / if          " Around/inside function
ac / ic          " Around/inside class
al / il          " Around/inside loop
aa / ia          " Around/inside parameter
]f / [f          " Next/previous function
]c / [c          " Next/previous class
```

### Nix Development Workflow

**Global Nix operations** (available everywhere):

```vim
<leader>nr       " :NixRun (with prompt)
<leader>nb       " :NixBuild (with prompt)
<leader>ns       " Enter nix develop shell
<leader>nu       " Update flake.lock
<leader>nc       " Check flake
<leader>ni       " Show flake info
<leader>nS       " Search packages (with prompt)
<leader>ne       " Evaluate expression (with prompt)
<leader>nC       " Clean nix store

" Quick file access
<leader>ef       " Edit flake.nix
<leader>ed       " Edit default.nix
```

**Nix file-specific mappings** (in .nix files):

```vim
<localleader>r   " Run current flake
<localleader>b   " Build current flake
<localleader>c   " Check current flake
<localleader>u   " Update flake.lock
<localleader>s   " Enter nix shell
<localleader>i   " Show flake info
```

### Lisp Development

```vim
" Terminal-based REPL workflow
:terminal sbcl    " Start SBCL in terminal split
:terminal         " General terminal (customize as needed)

" Vim-sexp provides paredit-style editing
" Standard text objects work semantically:
di(              " Delete inside s-expression
ya(              " Yank around s-expression
ci(              " Change inside s-expression
```

## Development Workflow

### Vim Workflow

1. **Find files**: `<leader>ff` then type partial name, use Tab completion
2. **Project search**: `<leader>fw` for grep-based search across project
3. **Navigate results**: Use quickfix list with `]q`/`[q` to jump between matches
4. **Buffer management**: `<leader>fb` to switch, `[b`/`]b` to cycle
5. **Code navigation**: Use LSP when available (`gd`, `gr`), fall back to vim's tag system
6. **REPL development**: `:terminal sbcl` for direct REPL interaction

### Nix Development Cycle

1. **Edit**: Use `<leader>ef` to quickly access flake.nix
2. **Test**: `<leader>nr` to run your current flake
3. **Build**: `<leader>nb` to build specific outputs
4. **Develop**: `<leader>ns` to enter development environment
5. **Update**: `<leader>nu` when dependencies need updating
6. **Check**: `<leader>nc` to validate your flake

**In .nix files**: Use local leader mappings for quick iteration:

- `<localleader>r` to test changes immediately
- `<localleader>c` to check syntax and structure

## Customization

### Adding a New Language

Edit `default.nix` and add to `supportedLanguages`:

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

The configuration automatically:

- Includes the LSP server in the build
- Generates setup code
- Adds the treesitter parser
- Configures formatting

### Adding Key Bindings

Follow the established patterns:

- `<leader>f*` for finding operations
- `<leader>g*` for git operations
- `<leader>c*` for code operations
- `<leader>n*` for nix operations
- Use `<localleader>` for filetype-specific operations

### File Structure

- `default.nix` - Main Neovim configuration and package definition
- `flake.nix` - Nix flake with inputs and outputs
- `vimrc.vim` - Core vim configuration following traditional patterns

## License

MIT
