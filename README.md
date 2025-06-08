# Nvim-Nix

A reproducible, declarative Neovim configuration using Nix flakes, following
a minimalist Vim philosophy with essential modern enhancements.

## Features

- 🔧 **Minimal**: Only 8 essential plugins for maximum performance and focus
- ⚡ **Just Works**: Reproducible setup with zero configuration on any machine with Nix

## Quick Start

```bash
# Try it immediately (full development environment)
nix run github:mikabohinen/nvim-nix#dev

# Just the editor (minimal)
nix run github:mikabohinen/nvim-nix#neovim

# Development shell with all tools
nix develop github:mikabohinen/nvim-nix
```

## Installation

### Home Manager

Add to your `home.nix`:

```nix
{
  inputs.nvim-nix.url = "github:mikabohinen/nvim-nix";

  # In your home configuration:
  imports = [ inputs.nvim-nix.homeManagerModules.default ];

  programs.nvimNix = {
    enable = true;
    enableDevTools = true; # Install formatters, linters, etc.
  };
}
```

### NixOS System-wide

Add to your `configuration.nix`:

```nix
{
  inputs.nvim-nix.url = "github:mikabohinen/nvim-nix";

  # In your system configuration:
  imports = [ inputs.nvim-nix.nixosModules.default ];

  programs.nvimNix = {
    enable = true;
    defaultEditor = true;
    enableDevTools = true;
  };
}
```

### Package Variants

- **`#neovim`**: Minimal editor with LSP support only
- **`#default`**: Full editor with all development tools
- **`#dev`**: App launcher with proper PATH for all tools
- **`#dev-tools`**: Just the development tools (formatters, linters, etc.)

## Philosophy

This configuration follows a minimalist approach. It embodies the belief that
power comes from mastery of core tools, not accumulation of features. Every
exclusion is intentional.

### Core Principles

**Vim-First Approach**: Modern features supplement, never replace, core Vim functionality. File finding uses `:find **/*`, searching uses `:grep` and `:vimgrep`, navigation relies on native commands. LSP and Treesitter enhance this foundation without replacing it.

**Reproducible Development**: Nix ensures identical environments across machines. Every dependency, from language servers to formatters, is declaratively specified and automatically available.

**Structural Thinking**: The configuration is organized around how you actually work - finding, searching, navigating, editing. Key mappings follow consistent patterns that scale with complexity.

**Manual Tool Mastery**: External tools (formatters, linters) remain external and are used intentionally. This builds transferable skills and deep understanding rather than editor dependencies.

**Absolute Control**: Plugin management through pure Nix expressions with cryptographic integrity. No hidden dependencies or external state.

**Exceptions**: Only one language gets special treatment - Lisp. Vim's text objects and structural editing work so naturally with Lisp's uniform syntax that specialized tools like paredit aren't luxuries, they're baseline usability.

## Plugin List

See [selection criteria](#Plugin-selection-criteria) for why these specific plugins are acceptable.

**Modern Necessities** (what vimscript can't handle well):

- **nvim-lspconfig**: Language server integration
- **nvim-treesitter + textobjects**: Enhanced syntax and structural navigation

**Editing** (amplify core Vim strengths):

- **vim-surround**: Text object manipulation
- **vim-repeat**: Quality of life addition
- **vim-vinegar**: Enhanced netrw

**Development Integration** (essential workflow tools):

- **vim-fugitive**: Git integration

**Lisp Exception** (structural editing for uniform syntax):

- **vim-sexp**: Paredit-style editing for s-expressions

**Total: 8 plugins** - 5 local (absolute control) + 3 nixpkgs (complex builds)

### Plugin Management

Pure Nix declarative plugin management replaces traditional plugin managers.

#### Local Plugins (5) - Managed via `plugins.nix`
```nix
# Declarative plugin definitions with exact version control
vim-surround = {
  owner = "tpope";
  repo = "vim-surround";
  rev = "3d188ed2113431cf8dac77be61b842acb64433d9";  # Exact commit
  sha256 = "sha256-abc123...";                       # Cryptographic integrity
};
```

#### Nixpkgs Plugins (3) - Managed via `default.nix`
Complex plugins that benefit from Nix's build system: nvim-lspconfig, nvim-treesitter, nvim-treesitter-textobjects.

#### Plugin Commands
```bash
# List all plugins with breakdown
nix run .#plugins list

# Show plugin statistics
nix run .#plugins stats

# Check for updates
nix run .#plugins check-updates

# Plugin management environment
nix develop .#plugins
```

### Plugin selection criteria

We include a plugin if it:

- ✅ Makes you a better developer - teaches better thinking about code, tools, or workflow
- ✅ Provides capabilities Vim fundamentally cannot - LSP protocol, syntax tree parsing, etc.
- ✅ Enhances Vim's philosophy - extends operators, text objects, or native patterns
- ✅ Reinforces good practices from the programming domain
- ✅ Has educational value - helps you understand tools or concepts more deeply

We exclude a plugin if it:

- ❌ Hides complexity you should understand - automation that prevents learning
- ❌ Replaces learning with convenience - shortcuts that bypass skill development
- ❌ Creates dependencies on specific abstractions - non-transferable workflows
- ❌ Violates Vim patterns - replaces rather than enhances native functionality
- ❌ Provides convenience over capability - nice-to-have rather than essential

#### Examples of excluded plugins

- **Fuzzy finders**: :find \*\*/\* is sufficient, and using :grep together with the quickfix list is better
- **Auto-formatters**: :!black % teaches you more
- **Visual git tools**: command-line git + fugitive forces you to grok git
- **Comment automation**: manual commenting teaches language syntax
- **Session managers**: :mksession covers 80% of use cases

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

## Desktop Integration

Nvim-Nix provides seamless GUI integration while maintaining the terminal-focused workflow:

### Terminal Emulator Support
- **Auto-detection**: Automatically finds and uses the best available terminal
- **8 Supported terminals**: kitty, alacritty, wezterm, gnome-terminal, konsole, terminator, xterm, st
- **Desktop environment aware**: Uses gnome-terminal on GNOME, konsole on KDE, etc.

### File Manager Integration
```nix
programs.nvimNix = {
  enable = true;
  terminalEmulator = "kitty";  # or "auto" for detection
  enableDesktopEntry = true;   # Creates "Open with Neovim" entries
};
```
After installation, you can:
- Right-click text files → "Open with Neovim"
- Find "Neovim" in your application menu
- Use file associations for various text formats

## Key Bindings

### Philosophy: Consistent Patterns

Key bindings follow **functional grouping**:

- **`<leader>f*`**: All "finding" operations (files, buffers, search)
- **`<leader>g*`**: Git operations
- **`<leader>c*`**: Code operations (LSP, diagnostics, formatting)
- **`<leader>n*`**: Nix development workflow
- **`<leader>w*`**: Workspace management (LSP)
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

" Window movement
<C-J>                   " Move to next window
<C-K>                   " Move to previous window
```

### Search & Navigation

```vim
" Enhanced search patterns (very magic mode)
<leader>/        " Search with \v (very magic)
<leader>?        " Reverse search with \v (very magic)

" Search control
<Esc><Esc>       " Clear search highlighting
n / N            " Next/previous search (auto-centered)
* / #            " Search word under cursor (auto-centered)
```

### LSP & Diagnostics

**Core LSP navigation** (buffer-local, only when LSP is attached):

```vim
gd               " Go to definition
gr               " Go to references
gi               " Go to implementation
gD               " Go to declaration
gy               " Go to type definition
K                " Hover documentation
<leader>cr       " Rename symbol
<leader>ca       " Code actions (normal and visual mode)
<leader>ck       " Signature help
```

**Diagnostic navigation** (buffer-local, following `]q`/`[q` pattern):

```vim
]d / [d          " Next/previous diagnostic
]D / [D          " Next/previous error (skips warnings)
```

**Diagnostic display** (buffer-local):

```vim
<leader>cd       " Show line diagnostics in floating window
<leader>cD       " Send buffer diagnostics to location list
<leader>cw       " Send workspace diagnostics to quickfix
```

**Global diagnostic commands** (always available):

```vim
<leader>cq       " Send all diagnostics to quickfix
<leader>cl       " Send buffer diagnostics to location list
<leader>cs       " Show diagnostic summary count
<leader>cR       " Restart LSP client
<leader>cI       " Show LSP info
```

**Workspace management** (buffer-local, LSP-specific):

```vim
<leader>wa       " Add workspace folder
<leader>wr       " Remove workspace folder
<leader>wl       " List workspace folders
```

### Treesitter Features

**Text objects** (work with operators like `d`, `y`, `c`):

```vim
af / if          " Around/inside function
ac / ic          " Around/inside class
al / il          " Around/inside loop
aa / ia          " Around/inside parameter
```

**Movement**:

```vim
]f / [f          " Next/previous function start
]c / [c          " Next/previous class start
]F / [F          " Next/previous function end
]C / [C          " Next/previous class end
```

**Incremental selection** (for precise text selection):

```vim
gnn              " Start incremental selection
grn              " Increment to next node
grc              " Increment to scope
grm              " Decrement selection
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

## Commands

### Utility Commands

```vim
:H [topic]           " Open help in vertical split (e.g., :H buffers)
:O [file...]         " Open file(s) with system default application
:StripWhitespace     " Remove trailing whitespace from entire buffer
```

### Command Shortcuts

```vim
:W                   " Same as :w (save)
:Q                   " Same as :q (quit)
:WQ / :Wq            " Same as :wq (save and quit)
:Qa                  " Same as :qa (quit all)
```

### Configuration Management

```vim
:EditVimrc           " Edit the main vimrc configuration
:ReloadVimrc         " Reload the vimrc configuration
```

### Nix Development Commands

**File Management**:
```vim
:EditFlake           " Edit flake.nix
:EditDefault         " Edit default.nix
```

**Build and Run**:
```vim
:NixRun [target]     " Run nix package (defaults to current flake)
:NixBuild [target]   " Build nix package (defaults to current flake)
:NixShell [target]   " Enter nix develop shell
```

**Package Management**:
```vim
:NixUpdate [input]   " Update flake.lock (optionally specific input)
:NixCheck [args]     " Run nix flake check
:NixClean            " Clean nix store (with confirmation)
:NixInfo [target]    " Show flake information
```

**Search and Analysis**:
```vim
:NixSearch <term>     " Search nixpkgs for packages
:NixEval <expr>       " Evaluate nix expression
:NixWhyDepends <args> " Show dependency chain
```

### LSP Diagnostic Commands

```vim
:DiagnosticsQF                 " Send all diagnostics to quickfix
:DiagnosticsLoc                " Send buffer diagnostics to location list
:DiagnosticsAll                " Show all project diagnostics
:DiagnosticsErrors             " Show only errors
:DiagnosticsWarnings           " Show only warnings
:DiagnosticsToggleVirtualText  " Toggle inline diagnostic text
:LspRestart                    " Restart LSP client
:LspInfo                       " Show LSP client information
```

## Module Configuration

### Home Manager Options

```nix
programs.nvimNix = {
  enable = true;
  package = pkgs.my-neovim;            # Custom package override
  enableDevTools = true;               # Install formatters/linters
  extraConfig = "vim.opt.tabstop = 2"; # Custom Lua config
  shellAliases = {                     # Shell aliases
    vi = "nvim";
    vim = "nvim";
    v = "nvim-gui";                    # GUI launcher
  };

  # Desktop integration
  terminalEmulator = "kitty";          # or "auto"
  installTerminalEmulator = true;      # Install the terminal
  enableDesktopEntry = true;           # Create desktop entries
  createGuiWrapper = true;             # Create nvim-gui command
};
```

### NixOS Options

```nix
programs.nvimNix = {
  enable = true;
  package = pkgs.my-neovim;     # Custom package override
  defaultEditor = true;         # Set as system EDITOR
  enableDevTools = true;        # Install tools system-wide

  # Desktop integration
  terminalEmulator = "auto";    # Auto-detect based on DE
  enableDesktopEntry = true;    # System-wide desktop entries
  enableGitIntegration = true;  # Configure git to use nvim
};
```

## Development Workflow

### Quick Commands
```bash
# List installed plugins with breakdown
nix run .#plugins list

# Show plugin statistics
nix run .#plugins stats

# Check for plugin updates
nix run .#plugins check-updates

# Plugin management environment
nix develop .#plugins
```

### Adding a Language

Edit `lib/languages.nix` and add to `supportedLanguages`:

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

### Adding a Plugin

Edit `plugins.nix` and add to `pluginSources`:

```nix
vim-commentary = {
  owner = "tpope";
  repo = "vim-commentary";
  rev = "b90f965880e761a026ae0c1e1d7174e65e4d7b45";  # Get with nix-prefetch-github
  sha256 = lib.fakeHash;  # Will be computed automatically
};
```

### Updating Plugins

```bash
# Get latest commit info
nix-prefetch-github tpope vim-surround

# Update plugins.nix with new rev and sha256
# Test the build
nix build .#neovim
```

## Architecture

### Three-Layer Approach

Nvim-Nix employs a three-layer architecture that leverages the strengths of
Nix, Vimscript, and Lua respectively. Each language does what it is good at and
no more:

#### Nix Layer (Infrastructure)

*"What should exist"*

- **Declarative Environment**: Packages, plugins, language servers, formatters
- **Reproducible Systems**: Identical setups across machines and time
- **Integration Logic**: Desktop entries, terminal detection, system configuration
- **Dependency Management**: All external tools with exact versions

```nix
# Nix handles: "Make these tools available"
languageServers = [ pkgs.pyright pkgs.rust-analyzer ];
plugins = [ vim-surround vim-fugitive ];
```

#### Vimscript Layer (Behavior)

*"How should Vim behave"*

- **Core Workflow**: Traditional Vim commands, mappings, patterns
- **User Interface**: Status line, quickfix integration, helper functions
- **Command Definitions**: All :commands and <leader> mappings
- **Editor Behavior**: Settings, autocommands, traditional vim features

```vim
" Vimscript handles: "How should the editor behave"
nnoremap <leader>fw :grep "" .<Left><Left><Left>
command! StripWhitespace call StripTrailingWhitespace()
```

#### Lua Layer (Modern Features)

*"How should modern features work"*

- **LSP Configuration**: Language server setup, capabilities, handlers
- **Dynamic Behavior**: Buffer-local keymaps that activate in response to LSP events
- **Modern APIs**: Diagnostic configuration, treesitter, floating windows
- **Event-Driven**: Autocommands that respond to LSP attachment

```lua
-- Lua handles: "How should modern features integrate"
vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(event)
    vim.keymap.set('n', 'gd', vim.lsp.buf.definition, {buffer = event.buf})
  end,
})
```

#### Clean Boundaries

Each layer has clear responsibilities and interfaces:

- **Nix → Lua**: Provides tools and generates configuration
- **Lua → Vimscript**: Calls vim commands and integrates with existing patterns
- **Vimscript → Lua**: Invokes lua functions for modern features
- **No layer bypassing**: Each respects the others' domains

This architecture ensures that adding a language server happens in Nix, defining
key-mappings happens in Vimscript, configuring LSP behavior happens in Lua. Each
language does what it is meant to do.

### File Structure

- `flake.nix` - Flake inputs/outputs with clean organization
- `plugins.nix` - Declarative plugin definitions with exact versions
- `lib/languages.nix` - Language support definitions
- `lib/plugin-management.nix` - Nix plugin utilities
- `lib/desktop.nix` - Desktop integration utilities
- `modules/` - Home Manager and NixOS integration modules
- `vimrc.vim` - Core vim configuration following traditional patterns

### Plugin Architecture

```
Plugins (8 total)
├── Local Plugins (5) - plugins.nix
│   ├── vim-surround
│   ├── vim-vinegar
│   ├── vim-repeat
│   ├── vim-fugitive
│   └── vim-sexp
└── Nixpkgs Plugins (3) - default.nix
    ├── nvim-lspconfig
    ├── nvim-treesitter
    └── nvim-treesitter-textobjects
```

**Benefits**:
- Local plugins: Absolute control with exact version pinning
- Nixpkgs plugins: Complex builds handled by Nix ecosystem
- All plugins: Automatic loading, no manual `:packadd` required

## Troubleshooting

### Formatters Not Available

**Problem**: Commands like `:!black %` fail with "command not found"

**Solution**: You're using the minimal variant. Use one of:
- `nix run github:mikabohinen/nvim-nix#dev` (app with tools)
- Install via Home Manager/NixOS modules with `enableDevTools = true`
- Use `nix develop` for development shell

### LSP Servers Not Found

**Problem**: LSP features not working

**Solution**: Ensure you're using the full package or have `enableDevTools = true` in modules

### Custom Configuration

Add custom config via Home Manager:

```nix
programs.nvimNix.extraConfig = ''
  -- Custom Lua configuration
  vim.opt.relativenumber = false
  vim.keymap.set('n', '<leader>w', ':w<CR>')
'';
```

### Desktop Integration Issues

**Problem**: Desktop entries not appearing or wrong terminal used

**Solution**:
```nix
programs.nvimNix = {
  enable = true;
  terminalEmulator = "kitty";  # Force specific terminal
  installTerminalEmulator = true;
};
```

Check available terminals:
```bash
nix eval .#lib.versionInfo.available-terminals
```

### Plugin Management

**Problem**: Need to add, update, or remove plugins

**Solution**: Use built plugin tooling:

```bash
# List current plugins
nix run .#plugins list

# Check for updates
nix run .#plugins check-updates

# Get update instructions
nix run .#plugins update-info
```

Add plugins by editing `plugins.nix`:
```nix
new-plugin = {
  owner = "author";
  repo = "plugin-name";
  rev = "commit-hash";      # Get with nix-prefetch-github
  sha256 = lib.fakeHash;    # Auto-computed
};
```

## License

[MIT](./LICENSE)
